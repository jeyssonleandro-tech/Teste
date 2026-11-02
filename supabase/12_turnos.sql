-- =============================================================
-- Lançamento por turno — ETE Industrial e ETE Sanitária
-- Rodar UMA VEZ, depois do 11_importacao_em_lote.sql.
--
-- Turnos: 1º das 06h às 18h, 2º das 18h às 06h.
--
-- REGRA DA VIRADA DA MEIA-NOITE
--   A medição pertence ao dia em que o TURNO COMEÇOU. Uma leitura
--   das 2h da manhã do dia 5, feita no turno que entrou às 19h do
--   dia 4, é lançada como dia 4. Sem isso o turno da noite ficaria
--   partido em dois dias e a soma do volume sairia pela metade.
--
-- O turno é característica da UNIDADE, não do parâmetro: quem opera
-- a ETA não vê o campo.
-- =============================================================

-- -------------------------------------------------------------
-- 1) Quais unidades trabalham por turno
-- -------------------------------------------------------------
alter table public.unidades
  add column if not exists usa_turno boolean not null default false;

comment on column public.unidades.usa_turno is
  'Se true, todo lançamento desta unidade exige turno.';

update public.unidades set usa_turno = true
 where nome in ('ETE Industrial', 'ETE Sanitária');

-- -------------------------------------------------------------
-- 2) O turno na leitura
-- -------------------------------------------------------------
alter table public.leituras
  add column if not exists turno smallint;

alter table public.leituras drop constraint if exists leitura_turno_valido;
alter table public.leituras add constraint leitura_turno_valido
  check (turno is null or turno in (1, 2));

comment on column public.leituras.turno is
  '1 = 06h-18h, 2 = 18h-06h. Nulo nas unidades que não usam turno. '
  'A data é sempre o dia em que o turno começou.';

-- Histórico: o que já existe nas duas ETEs vira 1º turno.
-- Decisão do supervisor. Vale saber ao comparar os primeiros meses:
-- parte desses lançamentos pode ter vindo do 2º turno.
update public.leituras l
   set turno = 1
  from public.unidades u
 where u.id = l.unidade_id and u.usa_turno and l.turno is null;

-- -------------------------------------------------------------
-- 3) Unicidade passa a incluir o turno
--    'nulls not distinct' é o que impede duplicata nas unidades sem
--    turno, onde a coluna fica nula: sem isso o Postgres trataria
--    cada nulo como um valor diferente e aceitaria repetição.
-- -------------------------------------------------------------
alter table public.leituras drop constraint if exists leitura_unica_por_dia;
alter table public.leituras drop constraint if exists leitura_unica_por_turno;
alter table public.leituras add constraint leitura_unica_por_turno
  unique nulls not distinct (unidade_id, parametro_id, data, turno);

-- -------------------------------------------------------------
-- 4) Alerta por turno
--    O supervisor definiu que qualquer turno fora da faixa deve
--    acender. Nas unidades com turno isso exige comparar pelos
--    EXTREMOS e não pelo valor consolidado — senão um 1º turno ruim
--    ficaria escondido atrás do 2º.
-- -------------------------------------------------------------
update public.parametros p
   set limite_base = 'diario'
 where (p.limite_inferior is not null or p.limite_superior is not null)
   and exists (select 1 from public.unidades u
                where u.usa_turno and u.tipo = p.aplica_a_tipo);

-- =============================================================
-- 5) VIEWS
--    Passa a existir um nível a mais na cadeia:
--      leituras (turno) → dia consolidado → semana / mês
--    O dia é a unidade atômica: semana e mês agregam dias, não
--    leituras soltas. Com turno faltando num dia, agregar leituras
--    cruas daria peso maior ao dia que teve os dois.
-- =============================================================

drop view if exists public.vw_leituras_turno    cascade;
drop view if exists public.vw_leituras_diarias  cascade;
drop view if exists public.vw_dashboard         cascade;
drop view if exists public.vw_dashboard_mensal  cascade;

-- 5.1) Detalhe por turno — alimenta a comparação no painel
create view public.vw_leituras_turno
with (security_invoker = on) as
select
  l.id,
  u.nome  as unidade,
  u.tipo  as tipo_unidade,
  u.usa_turno,
  p.nome  as parametro,
  p.unidade_medida,
  p.ordem as ordem_parametro,
  p.limite_inferior,
  p.limite_superior,
  l.data,
  coalesce(l.turno, 1) as turno,
  l.valor,
  l.observacao
from public.leituras l
join public.unidades   u on u.id = l.unidade_id
join public.parametros p on p.id = l.parametro_id
where u.ativo and p.ativo;

comment on view public.vw_leituras_turno is
  'Leituras turno a turno. Sem registrado_por — dado pessoal.';

-- 5.2) Dia consolidado — os turnos viram um número pela regra do
--      parâmetro, e os extremos brutos seguem junto para o alerta
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
    -- 'último' entre turnos é o turno mais alto do dia
    (array_agg(l.valor order by coalesce(l.turno, 1) desc))[1] as v_ultimo,
    count(*) as turnos_lancados
  from public.leituras l
  join public.unidades   u on u.id = l.unidade_id
  join public.parametros p on p.id = l.parametro_id
  where u.ativo and p.ativo and l.valor is not null
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
from por_dia;

comment on view public.vw_leituras_diarias is
  'Um número por dia: os turnos já consolidados pela regra do parâmetro. '
  'valor_min_dia e valor_max_dia são os extremos entre turnos.';

-- 5.3) Semana e mês — agregam DIAS, e carregam os extremos brutos
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
    on p.nome = d.parametro and p.ativo
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
where agregacao_extra is not null;

comment on view public.vw_dashboard is
  'Semana a partir dos dias consolidados. Extremos brutos por turno.';

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
    on p.nome = d.parametro and p.ativo
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
where agregacao_extra is not null;

comment on view public.vw_dashboard_mensal is
  'Mês de calendário a partir dos dias consolidados.';

-- 5.4) Comparação por turno, nas três granularidades numa view só
--      Uma leitura por unidade + parâmetro + dia + turno, então no
--      diário o valor é o próprio; semana e mês agregam pela regra
--      do parâmetro, dentro de cada turno.
drop view if exists public.vw_turnos;

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
    l.data,
    coalesce(l.turno, 1) as turno,
    l.valor
  from public.leituras l
  join public.unidades   u on u.id = l.unidade_id
  join public.parametros p on p.id = l.parametro_id
  where u.ativo and p.ativo and u.usa_turno and l.valor is not null
)
select 'diario' as granularidade, unidade, tipo_unidade, parametro, unidade_medida,
       ordem_parametro, turno, data as periodo, valor,
       limite_inferior, limite_superior
  from base
union all
select 'semanal', unidade, tipo_unidade, parametro, unidade_medida,
       ordem_parametro, turno, date_trunc('week', data)::date,
       case agregacao when 'soma'   then sum(valor)
                      when 'ultimo' then (array_agg(valor order by data desc))[1]
                      else               avg(valor) end,
       limite_inferior, limite_superior
  from base
 group by unidade, tipo_unidade, parametro, unidade_medida, ordem_parametro,
          agregacao, limite_inferior, limite_superior, turno, date_trunc('week', data)
union all
select 'mensal', unidade, tipo_unidade, parametro, unidade_medida,
       ordem_parametro, turno, date_trunc('month', data)::date,
       case agregacao when 'soma'   then sum(valor)
                      when 'ultimo' then (array_agg(valor order by data desc))[1]
                      else               avg(valor) end,
       limite_inferior, limite_superior
  from base
 group by unidade, tipo_unidade, parametro, unidade_medida, ordem_parametro,
          agregacao, limite_inferior, limite_superior, turno, date_trunc('month', data);

comment on view public.vw_turnos is
  'Série separada por turno, nas três granularidades. Só unidades com turno.';

-- -------------------------------------------------------------
-- 6) Permissões (o drop cascade derrubou os grants)
-- -------------------------------------------------------------
grant select on public.vw_leituras_turno   to authenticated;
grant select on public.vw_turnos           to authenticated;
grant select on public.vw_leituras_diarias to authenticated;
grant select on public.vw_dashboard        to authenticated;
grant select on public.vw_dashboard_mensal to authenticated;

-- -------------------------------------------------------------
-- 7) Importação em lote passa a aceitar turno
--    Em branco, numa unidade que usa turno, entra como 1º.
-- -------------------------------------------------------------
alter table public.importacao_leituras
  add column if not exists turno text;

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
         -- em unidade com turno, em branco entra como 1º; sem turno, fica nulo
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
   where unidade_id is not null and parametro_id is not null
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
   having count(*) > 0;
end $$;

-- =============================================================
-- CONFERINDO
--   select nome, tipo, usa_turno from public.unidades order by nome;
--   select turno, count(*) from public.leituras group by turno;
--   select unidade, parametro, data, turno, valor
--     from public.vw_leituras_turno order by data desc limit 10;
-- =============================================================
