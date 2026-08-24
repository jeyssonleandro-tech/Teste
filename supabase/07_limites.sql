-- =============================================================
-- Limites de conformidade por parâmetro
-- Rodar UMA VEZ, depois do 06_acesso_autenticado.sql.
--
-- O que muda:
--   • cada parâmetro pode ter limite inferior e/ou superior
--   • cada limite diz a que valor ele se aplica: ao número exibido
--     no período, ou ao valor de cada dia
--   • as views passam a entregar os limites e os extremos diários,
--     para o painel sinalizar o que saiu da faixa
-- =============================================================

-- -------------------------------------------------------------
-- 1) Colunas
-- -------------------------------------------------------------
alter table public.parametros
  add column if not exists limite_inferior numeric,
  add column if not exists limite_superior numeric,
  add column if not exists limite_base text not null default 'periodo'
  check (limite_base in ('periodo', 'diario'));

comment on column public.parametros.limite_base is
  'A que valor o limite se aplica na visão semanal. '
  '''periodo'': ao número agregado que o painel exibe (média, último). '
  '''diario'': ao valor de cada dia — usado quando o limite é diário '
  'mas o parâmetro é somado na semana, como os volumes de água.';

-- -------------------------------------------------------------
-- 2) Limites
--    Campo em branco na lista = sem limite daquele lado.
--    Limite inferior 0 em grandezas que não ficam negativas nunca
--    dispara; fica registrado por documentar a intenção.
-- -------------------------------------------------------------

-- ETE Industrial
update public.parametros set limite_superior = 6000, limite_inferior = 1000
 where nome = 'DQO Equalizado'    and aplica_a_tipo = 'ETE Industrial';
update public.parametros set limite_superior = 6000, limite_inferior = 1000
 where nome = 'DQO Químico'       and aplica_a_tipo = 'ETE Industrial';
update public.parametros set limite_superior = 7.5, limite_inferior = 4
 where nome = 'pH Equalizado'     and aplica_a_tipo = 'ETE Industrial';
update public.parametros set limite_superior = 7.5, limite_inferior = 4
 where nome = 'pH Químico'        and aplica_a_tipo = 'ETE Industrial';
update public.parametros set limite_superior = 12,  limite_inferior = 4
 where nome = 'pH Elev. Orgânico' and aplica_a_tipo = 'ETE Industrial';
update public.parametros set limite_superior = 200, limite_inferior = 0
 where nome = 'Acidez Reator'     and aplica_a_tipo = 'ETE Industrial';
update public.parametros set limite_superior = 100, limite_inferior = 0
 where nome = 'DQO Eflu Tratado'  and aplica_a_tipo = 'ETE Industrial';

-- ETE Sanitária
update public.parametros set limite_superior = 100, limite_inferior = 0
 where nome = 'DQO Eflu Tratado'  and aplica_a_tipo = 'ETE Sanitária';
update public.parametros set limite_superior = 10,  limite_inferior = 0
 where nome = 'Nitrogênio'        and aplica_a_tipo = 'ETE Sanitária';
update public.parametros set limite_superior = 1,   limite_inferior = 0
 where nome = 'Fósforo'           and aplica_a_tipo = 'ETE Sanitária';

-- ETA — só limite superior
update public.parametros set limite_superior = 180
 where nome = 'Vazão de tratamento' and aplica_a_tipo = 'ETA';
update public.parametros set limite_superior = 4, limite_inferior = 0
 where nome = 'Cloro Semi'          and aplica_a_tipo = 'ETA';

-- ETA — águas por produto: o limite é DIÁRIO, mas o parâmetro é
-- somado na semana. Sem limite_base = 'diario', o painel compararia
-- o total de 7 dias com um teto de 1 dia e acusaria desvio sempre.
update public.parametros set limite_superior = 1600, limite_base = 'diario'
 where nome = 'Água Cervejaria'   and aplica_a_tipo = 'ETA';
update public.parametros set limite_superior = 4600, limite_base = 'diario'
 where nome = 'Água refrigerante' and aplica_a_tipo = 'ETA';
update public.parametros set limite_superior = 1600, limite_base = 'diario'
 where nome = 'Água XS'           and aplica_a_tipo = 'ETA';

-- Represa
update public.parametros set limite_superior = 9.68, limite_inferior = 7
 where nome = 'Régua linimétrica' and aplica_a_tipo = 'Represa';

-- Sem limite definido: Volume Tratado (ETA e ETE), Turbidez,
-- Vazão de captação, Pluviometria, Vazão de Entrada,
-- DQO Eflu Bruto, Volume de produção.

-- -------------------------------------------------------------
-- 3) Visão diária — o limite se compara ao valor do próprio dia
-- -------------------------------------------------------------
drop view if exists public.vw_leituras_diarias cascade;

create view public.vw_leituras_diarias
with (security_invoker = on) as
select
  l.id,
  u.nome  as unidade,
  u.tipo  as tipo_unidade,
  p.nome  as parametro,
  p.unidade_medida,
  p.ordem as ordem_parametro,
  p.limite_inferior,
  p.limite_superior,
  l.data,
  l.valor,
  l.observacao
from public.leituras l
join public.unidades   u on u.id = l.unidade_id
join public.parametros p on p.id = l.parametro_id
where u.ativo and p.ativo;

comment on view public.vw_leituras_diarias is
  'Leituras dia a dia, com os limites. Sem registrado_por — dado pessoal.';

-- -------------------------------------------------------------
-- 4) Visão semanal — entrega também os extremos do período
--    valor_min_dia / valor_max_dia respondem "algum dia saiu da
--    faixa?" para os parâmetros de limite diário.
-- -------------------------------------------------------------
drop view if exists public.vw_dashboard cascade;

create view public.vw_dashboard
with (security_invoker = on) as
with agregado as (
  select
    u.nome  as unidade,
    u.tipo  as tipo_unidade,
    p.nome  as parametro,
    p.unidade_medida,
    p.ordem as ordem_parametro,
    p.agregacao,
    p.agregacao_extra,
    p.limite_inferior,
    p.limite_superior,
    p.limite_base,
    date_trunc('week', l.data)::date as semana,
    sum(l.valor)                                 as v_soma,
    avg(l.valor)                                 as v_media,
    min(l.valor)                                 as v_min_dia,
    max(l.valor)                                 as v_max_dia,
    (array_agg(l.valor order by l.data desc))[1] as v_ultimo
  from public.leituras l
  join public.unidades   u on u.id = l.unidade_id
  join public.parametros p on p.id = l.parametro_id
  where u.ativo and p.ativo and l.valor is not null
  group by u.nome, u.tipo, p.nome, p.unidade_medida, p.ordem,
           p.agregacao, p.agregacao_extra,
           p.limite_inferior, p.limite_superior, p.limite_base,
           date_trunc('week', l.data)
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
-- A linha da agregação extra é outro recorte do mesmo lançamento.
-- Os limites não são carregados: um teto pensado para o total da
-- semana não vale para a média diária, e vice-versa.
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
  'Leituras agregadas por semana, com limites e extremos diários.';

-- -------------------------------------------------------------
-- 5) Permissões (o drop cascade derrubou os grants)
-- -------------------------------------------------------------
grant select on public.vw_dashboard        to authenticated;
grant select on public.vw_leituras_diarias to authenticated;

-- =============================================================
-- CONFERINDO
--   select aplica_a_tipo, nome, unidade_medida,
--          limite_inferior, limite_superior, limite_base
--     from public.parametros where ativo
--    order by aplica_a_tipo, ordem;
-- =============================================================
