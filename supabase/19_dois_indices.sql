-- =============================================================
-- Dois índices de água: sem cerveja e com cerveja
-- Rodar UMA VEZ, depois do 18_acumulado_mes.sql.
-- Idempotente.
--
-- O índice da cervejaria deixa de ser "quanta água a cervejaria gasta
-- por caixa da linha 5" e passa a ser o índice da fábrica INTEIRA —
-- mesmo denominador do outro, mas com a água da cervejaria dentro:
--
--   Índice de Água s/ Cerveja
--     = ((Volume FIT 100 − Água Cervejaria) + Caminhão Pipa + Volume Andina 1) × 1000
--       ÷ (Volume de produção × 5,678)
--
--   Índice de Água c/ Cerveja
--     = ((Volume FIT 100 + Caminhão Pipa + Volume Andina 1) × 1000)
--       ÷ (Volume de produção × 5,678)
--
-- Com o mesmo denominador, a diferença entre os dois é exatamente a
-- água da cervejaria — e os dois passam a ser comparáveis na mesma
-- escala, que é o que faz deles um par.
--
-- OS NOMES MUDAM, para a tela dizer o que cada número é. 'leituras'
-- aponta para o id do parâmetro, e índice não tem leitura: nada de
-- histórico se perde.
--
-- FICA SEM USO: 'Volume de produção L5'. Era o denominador do índice
-- antigo da cervejaria e agora não alimenta conta nenhuma. Continua
-- ativo — desativar é decisão de quem lança, e o comando está no fim
-- deste arquivo.
-- =============================================================

-- -------------------------------------------------------------
-- 1) Os nomes
-- -------------------------------------------------------------
update public.parametros
   set nome = 'Índice de Água s/ Cerveja'
 where nome = 'Índice de Água' and aplica_a_tipo = 'ETA';

update public.parametros
   set nome = 'Índice de Água c/ Cerveja', ordem = 6
 where nome = 'Índice de Água Cervejaria' and aplica_a_tipo = 'ETA';

-- o acumulado do mês acompanha os nomes novos
update public.parametros
   set acumula_mes = true
 where nome in ('Índice de Água s/ Cerveja', 'Índice de Água c/ Cerveja')
   and aplica_a_tipo = 'ETA';

-- -------------------------------------------------------------
-- 2) O cálculo
--    'create or replace' preserva as views do dashboard que dependem
--    desta — as colunas são as mesmas.
-- -------------------------------------------------------------
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
    ) as producao_cxu
  from public.leituras l
  join public.unidades   u on u.id = l.unidade_id
  join public.parametros p on p.id = l.parametro_id
  where u.ativo and p.ativo and l.valor is not null
  group by l.data
),
-- Os dois índices dividem o mesmo denominador e diferem só no que entra
-- no numerador. Um índice novo é mais uma linha aqui.
por_dia as (
  select 'Índice de Água s/ Cerveja'::text as parametro, data,
         (fit100_m3 - coalesce(agua_cervejaria_m3, 0))
           + coalesce(outras_agua_m3, 0) as agua_m3,
         producao_cxu
    from insumos
  union all
  select 'Índice de Água c/ Cerveja', data,
         fit100_m3 + coalesce(outras_agua_m3, 0),
         producao_cxu
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
  'Os dois índices de água — sem e com a cervejaria —, por dia, semana e '
  'mês. Mesmo denominador nos dois. Cada período divide a soma da água '
  'pela soma da produção: razão nunca se agrega por média.';

-- =============================================================
-- CONFERINDO
--   select granularidade, parametro, periodo, valor, agua_m3, producao_cxu
--     from public.vw_indice_agua
--    where granularidade = 'diario'
--    order by periodo desc, parametro limit 20;
--
--   -- a diferença entre os dois tem de ser a água da cervejaria:
--   select periodo,
--          max(agua_m3) filter (where parametro like '%c/ Cerveja')
--        - max(agua_m3) filter (where parametro like '%s/ Cerveja') as cervejaria_m3
--     from public.vw_indice_agua where granularidade = 'diario'
--    group by periodo order by periodo desc limit 10;
--
--   -- para tirar do formulário o insumo que ficou sem uso:
--   -- update public.parametros set ativo = false
--   --  where nome = 'Volume de produção L5' and aplica_a_tipo = 'Produção';
-- =============================================================
