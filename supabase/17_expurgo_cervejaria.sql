-- =============================================================
-- Índice de Água — a água da cervejaria sai da conta
-- Rodar UMA VEZ, depois do 16_tanques.sql.
-- Idempotente: é só uma view recriada.
--
-- A água que vai para a cervejaria já é medida pelo Índice de Água
-- Cervejaria. Mantê-la também no índice geral cobrava a mesma água duas
-- vezes e escondia o desempenho do resto da fábrica atrás do consumo de
-- uma linha só.
--
-- Numerador novo — o desconto acontece ANTES da soma:
--
--     (Volume FIT 100 − Água Cervejaria) + Caminhão Pipa + Volume Andina 1
--
-- O denominador não muda: Volume de produção × 5,678.
-- O Índice de Água Cervejaria também não muda.
--
-- DOIS CUIDADOS, registrados porque mudam o número:
--
--   1. Dia sem 'Água Cervejaria' lançada desconta zero. É o único
--      tratamento possível — o que não foi medido não pode ser
--      estimado —, mas o índice daquele dia sai mais alto do que a
--      realidade. Vale conferir a consulta do fim deste arquivo.
--
--   2. Se a Água Cervejaria for MAIOR que o Volume FIT 100, o índice sai
--      negativo. É lançamento errado, não operação: um índice negativo
--      não existe. Optou-se por deixá-lo aparecer em vez de esconder o
--      dia — número absurdo na tela é pedido de correção; dia que some
--      em silêncio, ninguém procura.
-- =============================================================

create or replace view public.vw_indice_agua
with (security_invoker = on) as
with insumos as (
  select
    l.data,
    sum(l.valor) filter (
      where u.tipo = 'ETA' and p.nome = 'Volume FIT 100'
    ) as fit100_m3,
    sum(l.valor) filter (
      where u.tipo = 'ETA' and p.nome in ('Caminhão Pipa', 'Volume Andina 1')
    ) as outras_agua_m3,
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
         (fit100_m3 - coalesce(agua_cervejaria_m3, 0))
           + coalesce(outras_agua_m3, 0) as agua_m3,
         producao_cxu
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
  'Os índices de água por dia, semana e mês. O geral já vem sem a água '
  'da cervejaria. Cada período divide a soma da água pela soma da '
  'produção — razão nunca se agrega por média.';

-- =============================================================
-- CONFERINDO
--   -- dias em que a cervejaria não foi lançada (o desconto foi zero):
--   select l.data
--     from public.leituras l
--     join public.unidades   u on u.id = l.unidade_id
--     join public.parametros p on p.id = l.parametro_id
--    where u.tipo = 'ETA'
--    group by l.data
--   having count(*) filter (where p.nome = 'Volume FIT 100')  > 0
--      and count(*) filter (where p.nome = 'Água Cervejaria') = 0
--    order by l.data desc limit 20;
--
--   -- índice negativo = cervejaria maior que o FIT 100 em algum dia:
--   select * from public.vw_indice_agua
--    where granularidade = 'diario' and valor < 0 order by periodo desc;
-- =============================================================
