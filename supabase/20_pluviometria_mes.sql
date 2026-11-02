-- =============================================================
-- Pluviometria: o mês inteiro, não o último dia
-- Rodar UMA VEZ, depois do 19_dois_indices.sql. Idempotente.
--
-- Chuva de um dia não diz nada sozinha; o que a operação acompanha é
-- quanto choveu no mês. A Pluviometria entra na mesma marcação que o
-- índice de água e a vazão de captação — e o painel acumula cada uma
-- pela regra que ela já tem:
--
--   agregacao 'soma'   → SOMA do mês      (Pluviometria)
--   agregacao 'razao'  → soma ÷ soma      (os dois índices de água)
--   demais             → média do período (Vazão de captação)
--
-- Nada de coluna nova: a regra de agregação já está em 'parametros' e é
-- a mesma que o banco usa para fechar semana e mês.
-- =============================================================

update public.parametros
   set acumula_mes = true
 where nome = 'Pluviometria' and aplica_a_tipo = 'Represa';

-- =============================================================
-- CONFERINDO
--   select nome, aplica_a_tipo, unidade_medida, agregacao, acumula_mes
--     from public.parametros where acumula_mes order by aplica_a_tipo, ordem;
-- =============================================================
