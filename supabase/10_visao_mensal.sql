-- =============================================================
-- Visão mensal
-- Rodar UMA VEZ, depois do 09_excluir_usuario.sql.
--
-- Mesma lógica da visão semanal, fechando por MÊS DE CALENDÁRIO —
-- do dia 1 ao último dia. É o corte que bate com relatório,
-- fechamento e conta de água.
--
-- As regras de agregação são as mesmas de sempre: soma para
-- acumulados, média para concentrações e taxas, último valor para
-- níveis e análises.
-- =============================================================

drop view if exists public.vw_dashboard_mensal;

create view public.vw_dashboard_mensal
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
    date_trunc('month', l.data)::date as mes,
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
           date_trunc('month', l.data)
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
-- Igual à visão semanal: a linha da agregação extra não carrega
-- limites, porque um teto pensado para o total não vale para a média.
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
  'Leituras agregadas por mês de calendário, com limites e extremos diários.';

grant select on public.vw_dashboard_mensal to authenticated;

-- =============================================================
-- CONFERINDO
--   select unidade, parametro, mes, valor
--     from public.vw_dashboard_mensal
--    order by mes desc limit 10;
-- =============================================================
