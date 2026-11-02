-- =============================================================
-- Acumulado do mês — quais parâmetros se leem pelo acumulado
-- Rodar UMA VEZ, depois do 17_expurgo_cervejaria.sql.
-- Idempotente.
--
-- Índice e vazão de captação não se lêem pelo valor de um dia: o que
-- interessa é como o mês está fechando. Estes parâmetros passam a ser
-- exibidos no painel como ACUMULADO do mês corrente — no diário e no
-- semanal, cada ponto é o acumulado até ali.
--
-- No modo mensal nada muda: o valor do mês já é o fechamento.
--
-- Para o índice, "acumulado" é soma da água ÷ soma da produção do
-- período — o painel faz isso ponderando cada ponto pela produção do
-- dia, que é a mesma conta. Razão nunca se agrega por média simples.
-- Para a vazão de captação, é a média dos dias decorridos.
-- =============================================================

alter table public.parametros
  add column if not exists acumula_mes boolean not null default false;

comment on column public.parametros.acumula_mes is
  'true = o painel mostra o acumulado do mês, não o valor do período.';

update public.parametros
   set acumula_mes = true
 where (nome in ('Índice de Água', 'Índice de Água Cervejaria') and aplica_a_tipo = 'ETA')
    or (nome = 'Vazão de captação' and aplica_a_tipo = 'Represa');

-- =============================================================
-- CONFERINDO
--   select nome, aplica_a_tipo, unidade_medida, agregacao, acumula_mes
--     from public.parametros where acumula_mes order by aplica_a_tipo, ordem;
--
--   -- para tirar o índice da cervejaria do acumulado, se preferir:
--   -- update public.parametros set acumula_mes = false
--   --  where nome = 'Índice de Água Cervejaria' and aplica_a_tipo = 'ETA';
-- =============================================================
