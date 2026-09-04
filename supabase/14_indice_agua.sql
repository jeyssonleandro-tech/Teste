-- =============================================================
-- Índices de Água — parâmetros calculados, com insumos ocultos
-- Rodar UMA VEZ, depois do 13_ete_sanitaria.sql.
-- Idempotente: rodar de novo corrige o cadastro e recria as views.
--
-- Duas fórmulas acordadas:
--
--   Índice de Água (sem cervejaria)
--     = (Volume Tratado + Caminhão Pipa) / (Volume de produção × 5,678)
--
--   Índice de Água Cervejaria
--     = Água Cervejaria / (Volume de produção L5 × 5,678)
--
-- Insumos:
--   • Volume Tratado        — ETA, m3, já cadastrado, visível
--   • Água Cervejaria       — ETA, m3, já cadastrado, visível
--   • Caminhão Pipa         — ETA, m3, NOVO, oculto no dashboard
--   • Volume de produção    — Produção, CXU, já cadastrado, visível
--   • Volume de produção L5 — Produção, CXU, NOVO, oculto no dashboard
--   • 5,678 — litros por caixa unitária (CXU)
--
-- Conversão: o numerador está em m3 e o denominador vira litros, então
-- o numerador é multiplicado por 1000. Sem isso o índice sairia mil
-- vezes menor (0,001 em vez de 1,3 L/L). Os dois fatores estão isolados
-- na view abaixo — se algum dia mudarem, mexe-se num lugar só.
--
-- Razão não se agrega por média: o índice da semana é a soma da água do
-- período dividida pela soma da produção do período, nunca a média dos
-- índices diários. Por isso cada granularidade é calculada direto das
-- leituras, e não a partir do índice do dia.
-- =============================================================

-- -------------------------------------------------------------
-- 1) Duas colunas novas em 'parametros'
--
--    exibir_no_painel — separa "o que se lança" de "o que se mostra".
--    O insumo continua sendo lançado, auditado e importado como
--    qualquer outro; só não ocupa espaço no dashboard.
--
--    calculado — o parâmetro não é medido, é conta. Não aparece no
--    formulário de lançamento e não vem de 'leituras'.
-- -------------------------------------------------------------
alter table public.parametros
  add column if not exists exibir_no_painel boolean not null default true,
  add column if not exists calculado        boolean not null default false;

comment on column public.parametros.exibir_no_painel is
  'false = insumo: lança-se normalmente, mas fica fora do dashboard.';
comment on column public.parametros.calculado is
  'true = resultado de conta, não de medição. Fora do formulário.';

-- 'razao' entra como regra de agregação: soma do numerador dividida
-- pela soma do denominador do período.
alter table public.parametros drop constraint if exists parametros_agregacao_check;
alter table public.parametros
  add constraint parametros_agregacao_check
  check (agregacao in ('media', 'soma', 'ultimo', 'razao'));

-- -------------------------------------------------------------
-- 2) Os quatro parâmetros — dois índices e dois insumos ocultos
-- -------------------------------------------------------------
--
--    Teto do índice: 1,33 L/L. limite_base fica em 'periodo' — o valor
--    comparado é o que está na tela. Num índice é o certo: a semana que
--    fecha em 1,28 está dentro da meta mesmo tendo tido um dia ruim, e é
--    o fechamento do período que a meta cobra.
insert into public.parametros
  (nome, unidade_medida, aplica_a_tipo, ordem, agregacao,
   exibir_no_painel, calculado, limite_superior) values
  ('Índice de Água',           'L/L', 'ETA',       5, 'razao', true,  true,  1.33),
  ('Índice de Água Cervejaria','L/L', 'ETA',       6, 'razao', true,  true,  null),
  ('Caminhão Pipa',            'm3',  'ETA',      90, 'soma',  false, false, null),
  ('Volume de produção L5',    'CXU', 'Produção', 20, 'soma',  false, false, null)
on conflict (nome, aplica_a_tipo) do update
   set unidade_medida   = excluded.unidade_medida,
       ordem            = excluded.ordem,
       agregacao        = excluded.agregacao,
       exibir_no_painel = excluded.exibir_no_painel,
       calculado        = excluded.calculado,
       limite_superior  = excluded.limite_superior,
       limite_base      = 'periodo';

-- -------------------------------------------------------------
-- 3) O cálculo, nas três granularidades
--    Uma linha por período em que houve água tratada E produção.
--    Faltando qualquer um dos dois lados, o índice não existe — e é
--    melhor não aparecer do que aparecer errado.
-- -------------------------------------------------------------
drop view if exists public.vw_indice_agua cascade;

create view public.vw_indice_agua
with (security_invoker = on) as
with insumos as (
  select
    l.data,
    sum(l.valor) filter (
      where u.tipo = 'ETA' and p.nome in ('Volume Tratado', 'Caminhão Pipa')
    ) as agua_total_m3,
    sum(l.valor) filter (
      where u.tipo = 'ETA' and p.nome = 'Água Cervejaria'
    ) as agua_cervejaria_m3,
    sum(l.valor) filter (
      where p.nome = 'Volume de produção'
    ) as producao_cxu,
    sum(l.valor) filter (
      where p.nome = 'Volume de produção L5'
    ) as producao_l5_cxu
  from public.leituras l
  join public.unidades   u on u.id = l.unidade_id
  join public.parametros p on p.id = l.parametro_id
  where u.ativo and p.ativo and l.valor is not null
  group by l.data
),
-- Cada índice vira um par (água, produção) do dia. Um índice novo é
-- mais uma linha aqui — o resto da view não muda.
por_dia as (
  select 'Índice de Água'::text as parametro, data,
         agua_total_m3 as agua_m3, producao_cxu as producao_cxu
    from insumos
  union all
  select 'Índice de Água Cervejaria', data,
         agua_cervejaria_m3, producao_l5_cxu
    from insumos
),
-- Só entram os dias com os dois lados lançados. Um dia com água mas
-- sem produção somaria água ao numerador da semana sem somar nada ao
-- denominador, e inflaria o índice do período inteiro por causa de um
-- lançamento em falta. Melhor a semana pesar menos dias e estar certa.
validos as (
  select * from por_dia
   where agua_m3 is not null and coalesce(producao_cxu, 0) > 0
),
periodos as (
  select 'diario'::text as granularidade, parametro, data as periodo,
         agua_m3, producao_cxu
    from validos
  union all
  select 'semanal', parametro, date_trunc('week', data)::date,
         sum(agua_m3), sum(producao_cxu)
    from validos group by parametro, date_trunc('week', data)
  union all
  select 'mensal', parametro, date_trunc('month', data)::date,
         sum(agua_m3), sum(producao_cxu)
    from validos group by parametro, date_trunc('month', data)
)
select
  granularidade,
  parametro,
  periodo,
  round((agua_m3 * 1000) / (producao_cxu * 5.678), 3) as valor,
  agua_m3,
  producao_cxu
from periodos;

comment on view public.vw_indice_agua is
  'Os índices de água por dia, semana e mês. Cada período divide a soma '
  'da água pela soma da produção — razão nunca se agrega por média.';

-- -------------------------------------------------------------
-- 4) As views do dashboard passam a respeitar exibir_no_painel
--    e a receber o índice como se fosse mais um parâmetro da ETA.
-- -------------------------------------------------------------
drop view if exists public.vw_leituras_diarias cascade;
drop view if exists public.vw_dashboard        cascade;
drop view if exists public.vw_dashboard_mensal cascade;
drop view if exists public.vw_turnos           cascade;

-- 4.1) Dia consolidado
create view public.vw_leituras_diarias
with (security_invoker = on) as
with por_dia as (
  select
    u.nome  as unidade,
    u.tipo  as tipo_unidade,
    u.usa_turno,
    p.nome  as parametro,
    p.unidade_medida,
    p.ordem as ordem_parametro,
    p.agregacao,
    p.limite_inferior,
    p.limite_superior,
    p.limite_base,
    l.data,
    sum(l.valor) as v_soma,
    avg(l.valor) as v_media,
    min(l.valor) as v_min,
    max(l.valor) as v_max,
    (array_agg(l.valor order by coalesce(l.turno, 1) desc))[1] as v_ultimo,
    count(*) as turnos_lancados
  from public.leituras l
  join public.unidades   u on u.id = l.unidade_id
  join public.parametros p on p.id = l.parametro_id
  where u.ativo and p.ativo and p.exibir_no_painel and l.valor is not null
  group by u.nome, u.tipo, u.usa_turno, p.nome, p.unidade_medida, p.ordem,
           p.agregacao, p.limite_inferior, p.limite_superior, p.limite_base, l.data
)
select unidade, tipo_unidade, usa_turno, parametro, unidade_medida, ordem_parametro,
       agregacao, data,
       case agregacao when 'soma'   then v_soma
                      when 'ultimo' then v_ultimo
                      else               v_media end as valor,
       v_min as valor_min_dia,
       v_max as valor_max_dia,
       turnos_lancados,
       limite_inferior, limite_superior, limite_base
from por_dia
union all
-- os índices do dia entram pela porta da ETA, com os limites do cadastro
select u.nome, u.tipo, u.usa_turno, p.nome, p.unidade_medida, p.ordem,
       p.agregacao, i.periodo, i.valor,
       i.valor, i.valor, 1,
       p.limite_inferior, p.limite_superior, p.limite_base
  from public.vw_indice_agua i
  join public.parametros p
    on p.nome = i.parametro and p.aplica_a_tipo = 'ETA' and p.ativo and p.calculado
  join public.unidades u on u.tipo = 'ETA' and u.ativo
 where i.granularidade = 'diario';

comment on view public.vw_leituras_diarias is
  'Um número por dia: os turnos já consolidados pela regra do parâmetro. '
  'Inclui os índices de água e exclui os insumos ocultos.';

-- 4.2) Semana
create view public.vw_dashboard
with (security_invoker = on) as
with agregado as (
  select
    d.unidade, d.tipo_unidade, d.parametro, d.unidade_medida, d.ordem_parametro,
    d.agregacao, p.agregacao_extra,
    d.limite_inferior, d.limite_superior, d.limite_base,
    date_trunc('week', d.data)::date as semana,
    sum(d.valor)                                   as v_soma,
    avg(d.valor)                                   as v_media,
    min(d.valor_min_dia)                           as v_min_dia,
    max(d.valor_max_dia)                           as v_max_dia,
    (array_agg(d.valor order by d.data desc))[1]   as v_ultimo
  from public.vw_leituras_diarias d
  join public.parametros p
    on p.nome = d.parametro and p.ativo and not p.calculado
   and (p.aplica_a_tipo is null or p.aplica_a_tipo = d.tipo_unidade)
  group by d.unidade, d.tipo_unidade, d.parametro, d.unidade_medida, d.ordem_parametro,
           d.agregacao, p.agregacao_extra,
           d.limite_inferior, d.limite_superior, d.limite_base,
           date_trunc('week', d.data)
)
select unidade, tipo_unidade, parametro, unidade_medida, ordem_parametro,
       agregacao, semana,
       case agregacao when 'soma'   then v_soma
                      when 'ultimo' then v_ultimo
                      else               v_media end as valor,
       v_min_dia as valor_min_dia,
       v_max_dia as valor_max_dia,
       limite_inferior, limite_superior, limite_base
from agregado
union all
select unidade, tipo_unidade,
       parametro || case agregacao_extra
                      when 'soma'   then ' (total da semana)'
                      when 'media'  then ' (média diária)'
                      else               ' (último valor)' end,
       unidade_medida, ordem_parametro + 1,
       agregacao_extra, semana,
       case agregacao_extra when 'soma'   then v_soma
                            when 'ultimo' then v_ultimo
                            else               v_media end,
       v_min_dia, v_max_dia,
       null::numeric, null::numeric, 'periodo'
from agregado
where agregacao_extra is not null
union all
-- índices da semana: recalculados do zero, não são média dos dias
select u.nome, u.tipo, p.nome, p.unidade_medida, p.ordem,
       p.agregacao, i.periodo, i.valor, i.valor, i.valor,
       p.limite_inferior, p.limite_superior, p.limite_base
  from public.vw_indice_agua i
  join public.parametros p
    on p.nome = i.parametro and p.aplica_a_tipo = 'ETA' and p.ativo and p.calculado
  join public.unidades u on u.tipo = 'ETA' and u.ativo
 where i.granularidade = 'semanal';

comment on view public.vw_dashboard is
  'Semana a partir dos dias consolidados. O índice é recalculado pela '
  'razão das somas do período.';

-- 4.3) Mês
create view public.vw_dashboard_mensal
with (security_invoker = on) as
with agregado as (
  select
    d.unidade, d.tipo_unidade, d.parametro, d.unidade_medida, d.ordem_parametro,
    d.agregacao, p.agregacao_extra,
    d.limite_inferior, d.limite_superior, d.limite_base,
    date_trunc('month', d.data)::date as mes,
    sum(d.valor)                                   as v_soma,
    avg(d.valor)                                   as v_media,
    min(d.valor_min_dia)                           as v_min_dia,
    max(d.valor_max_dia)                           as v_max_dia,
    (array_agg(d.valor order by d.data desc))[1]   as v_ultimo
  from public.vw_leituras_diarias d
  join public.parametros p
    on p.nome = d.parametro and p.ativo and not p.calculado
   and (p.aplica_a_tipo is null or p.aplica_a_tipo = d.tipo_unidade)
  group by d.unidade, d.tipo_unidade, d.parametro, d.unidade_medida, d.ordem_parametro,
           d.agregacao, p.agregacao_extra,
           d.limite_inferior, d.limite_superior, d.limite_base,
           date_trunc('month', d.data)
)
select unidade, tipo_unidade, parametro, unidade_medida, ordem_parametro,
       agregacao, mes,
       case agregacao when 'soma'   then v_soma
                      when 'ultimo' then v_ultimo
                      else               v_media end as valor,
       v_min_dia as valor_min_dia,
       v_max_dia as valor_max_dia,
       limite_inferior, limite_superior, limite_base
from agregado
union all
select unidade, tipo_unidade,
       parametro || case agregacao_extra
                      when 'soma'   then ' (total do mês)'
                      when 'media'  then ' (média diária)'
                      else               ' (último valor)' end,
       unidade_medida, ordem_parametro + 1,
       agregacao_extra, mes,
       case agregacao_extra when 'soma'   then v_soma
                            when 'ultimo' then v_ultimo
                            else               v_media end,
       v_min_dia, v_max_dia,
       null::numeric, null::numeric, 'periodo'
from agregado
where agregacao_extra is not null
union all
select u.nome, u.tipo, p.nome, p.unidade_medida, p.ordem,
       p.agregacao, i.periodo, i.valor, i.valor, i.valor,
       p.limite_inferior, p.limite_superior, p.limite_base
  from public.vw_indice_agua i
  join public.parametros p
    on p.nome = i.parametro and p.aplica_a_tipo = 'ETA' and p.ativo and p.calculado
  join public.unidades u on u.tipo = 'ETA' and u.ativo
 where i.granularidade = 'mensal';

comment on view public.vw_dashboard_mensal is
  'Mês de calendário a partir dos dias consolidados.';

-- 4.4) Série por turno — só unidades com turno, então o índice (ETA)
--      não entra. O que muda é o filtro dos insumos ocultos.
create view public.vw_turnos
with (security_invoker = on) as
with base as (
  select
    u.nome  as unidade,
    u.tipo  as tipo_unidade,
    p.nome  as parametro,
    p.unidade_medida,
    p.ordem as ordem_parametro,
    p.agregacao,
    p.limite_inferior,
    p.limite_superior,
    p.limite_base,
    l.data,
    coalesce(l.turno, 1) as turno,
    l.valor
  from public.leituras l
  join public.unidades   u on u.id = l.unidade_id
  join public.parametros p on p.id = l.parametro_id
  where u.ativo and p.ativo and p.exibir_no_painel
    and u.usa_turno and l.valor is not null
)
select 'diario' as granularidade, unidade, tipo_unidade, parametro, unidade_medida,
       ordem_parametro, agregacao, turno, data as periodo, valor,
       valor as valor_min_dia, valor as valor_max_dia,
       limite_inferior, limite_superior, limite_base
  from base
union all
select 'semanal', unidade, tipo_unidade, parametro, unidade_medida,
       ordem_parametro, agregacao, turno, date_trunc('week', data)::date,
       case agregacao when 'soma'   then sum(valor)
                      when 'ultimo' then (array_agg(valor order by data desc))[1]
                      else               avg(valor) end,
       min(valor), max(valor),
       limite_inferior, limite_superior, limite_base
  from base
 group by unidade, tipo_unidade, parametro, unidade_medida, ordem_parametro,
          agregacao, limite_inferior, limite_superior, limite_base,
          turno, date_trunc('week', data)
union all
select 'mensal', unidade, tipo_unidade, parametro, unidade_medida,
       ordem_parametro, agregacao, turno, date_trunc('month', data)::date,
       case agregacao when 'soma'   then sum(valor)
                      when 'ultimo' then (array_agg(valor order by data desc))[1]
                      else               avg(valor) end,
       min(valor), max(valor),
       limite_inferior, limite_superior, limite_base
  from base
 group by unidade, tipo_unidade, parametro, unidade_medida, ordem_parametro,
          agregacao, limite_inferior, limite_superior, limite_base,
          turno, date_trunc('month', data);

comment on view public.vw_turnos is
  'Série de um turno isolado, nas três granularidades, com limites e '
  'extremos — para a visão por turno alertar igual à consolidada.';

-- -------------------------------------------------------------
-- 5) Permissões (o drop cascade derrubou os grants)
-- -------------------------------------------------------------
grant select on public.vw_indice_agua      to authenticated;
grant select on public.vw_leituras_diarias to authenticated;
grant select on public.vw_dashboard        to authenticated;
grant select on public.vw_dashboard_mensal to authenticated;
grant select on public.vw_turnos           to authenticated;

-- -------------------------------------------------------------
-- 6) Importação em lote: parâmetro calculado não entra
--    Os índices existem no cadastro, então sem isto a planilha
--    conseguiria gravar um índice à mão por cima da conta. Eles passam a
--    ser recusados com nome próprio no relatório — os insumos ocultos
--    ('Caminhão Pipa', 'Volume de produção L5') continuam importando.
-- -------------------------------------------------------------
create or replace function public.importar_leituras()
returns table (situacao text, linhas bigint, exemplos text)
language plpgsql
security invoker
as $$
declare
  gravadas bigint;
begin
  create temp table _norm on commit drop as
  select
    i.linha,
    nullif(trim(i.unidade), '')   as unidade,
    nullif(trim(i.parametro), '') as parametro,
    case
      when trim(i.data) ~ '^\d{4}-\d{1,2}-\d{1,2}$'  then to_date(trim(i.data), 'YYYY-MM-DD')
      when trim(i.data) ~ '^\d{1,2}/\d{1,2}/\d{4}$'  then to_date(trim(i.data), 'DD/MM/YYYY')
      else null
    end as data,
    case
      when trim(i.valor) is null or trim(i.valor) = '' then null
      when replace(replace(trim(i.valor), '.', ''), ',', '.') ~ '^-?\d+(\.\d+)?$'
           and trim(i.valor) like '%,%'
        then replace(replace(trim(i.valor), '.', ''), ',', '.')::numeric
      when trim(i.valor) ~ '^-?\d+(\.\d+)?$' then trim(i.valor)::numeric
      else null
    end as valor,
    case when trim(coalesce(i.turno, '')) ~ '^[12]$'
         then trim(i.turno)::smallint else null end as turno,
    nullif(trim(coalesce(i.observacao, '')), '') as observacao,
    trim(i.data) as data_crua, trim(i.valor) as valor_cru
  from public.importacao_leituras i;

  create temp table _resolvida on commit drop as
  select n.*,
         u.id as unidade_id,
         u.usa_turno,
         p.id as parametro_id,
         coalesce(p.calculado, false) as calculado,
         case when u.usa_turno then coalesce(n.turno, 1) else null end as turno_final
  from _norm n
  left join public.unidades u
         on lower(u.nome) = lower(n.unidade) and u.ativo
  left join public.parametros p
         on lower(p.nome) = lower(n.parametro) and p.ativo
        and (p.aplica_a_tipo is null or p.aplica_a_tipo = u.tipo);

  insert into public.leituras (unidade_id, parametro_id, data, turno, valor, observacao)
  select unidade_id, parametro_id, data, turno_final, valor, observacao
    from _resolvida
   where unidade_id is not null and parametro_id is not null and not calculado
     and data is not null and valor is not null
  on conflict (unidade_id, parametro_id, data, turno) do update
     set valor = excluded.valor,
         observacao = coalesce(excluded.observacao, public.leituras.observacao);

  get diagnostics gravadas = row_count;

  return query
  select 'gravadas'::text, gravadas,
         'linhas inseridas ou corrigidas em leituras'::text
  union all
  select 'data inválida', count(*),
         coalesce(string_agg(distinct data_crua, ' | ' order by data_crua), '')
    from _resolvida where data is null
   having count(*) > 0
  union all
  select 'valor inválido', count(*),
         coalesce(string_agg(distinct valor_cru, ' | ' order by valor_cru), '')
    from _resolvida where data is not null and valor is null
   having count(*) > 0
  union all
  select 'unidade não encontrada', count(*),
         coalesce(string_agg(distinct unidade, ' | ' order by unidade), '')
    from _resolvida where unidade_id is null
   having count(*) > 0
  union all
  select 'parâmetro não encontrado nessa unidade', count(*),
         coalesce(string_agg(distinct parametro || ' (' || coalesce(unidade,'?') || ')',
                             ' | ' order by parametro || ' (' || coalesce(unidade,'?') || ')'), '')
    from _resolvida where unidade_id is not null and parametro_id is null
   having count(*) > 0
  union all
  select 'parâmetro calculado — o banco é quem faz a conta', count(*),
         coalesce(string_agg(distinct parametro, ' | ' order by parametro), '')
    from _resolvida where calculado
   having count(*) > 0;
end $$;

-- =============================================================
-- CONFERINDO
--   -- o que está oculto no painel:
--   select nome, aplica_a_tipo from public.parametros
--    where not exibir_no_painel or calculado order by aplica_a_tipo, ordem;
--
--   -- os índices, dia a dia, com os insumos à vista:
--   select * from public.vw_indice_agua
--    where granularidade = 'diario' order by periodo desc, parametro limit 20;
-- =============================================================
