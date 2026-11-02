-- =============================================================
-- Teto do índice c/ cerveja, e o insumo da L5 sai de cena
-- Rodar UMA VEZ, depois do 20_pluviometria_mes.sql. Idempotente.
--
-- SOBRE "EXCLUIR" O VOLUME DE PRODUÇÃO L5: o parâmetro é DESATIVADO, não
-- apagado. Apagar a linha de 'parametros' esbarraria na trava de
-- integridade — 'leituras' aponta para ela com ON DELETE RESTRICT — e só
-- passaria depois de destruir todas as medições já lançadas. Desativado,
-- ele some do formulário, do painel e da importação, e o que a operação
-- já mediu continua no banco. Se um dia fizer falta, volta com um
-- 'ativo = true'.
-- =============================================================

-- -------------------------------------------------------------
-- 1) Teto de 1,40 L/L para o índice com cerveja
--    limite_base 'periodo': o valor comparado é o que está na tela, que
--    para este parâmetro é a média do mês. É o fechamento do período que
--    a meta cobra, não o pior dia.
-- -------------------------------------------------------------
update public.parametros
   set limite_superior = 1.40,
       limite_base     = 'periodo'
 where nome = 'Índice de Água c/ Cerveja' and aplica_a_tipo = 'ETA';

-- -------------------------------------------------------------
-- 2) O insumo que ficou sem uso
-- -------------------------------------------------------------
update public.parametros
   set ativo = false
 where nome = 'Volume de produção L5' and aplica_a_tipo = 'Produção';

-- =============================================================
-- CONFERINDO
--   select nome, aplica_a_tipo, unidade_medida, limite_superior,
--          limite_base, acumula_mes, ativo
--     from public.parametros where calculado order by ordem;
--
--   -- deve listar 'Vazão de Entrada' e 'Volume de produção L5':
--   select nome, aplica_a_tipo from public.parametros where not ativo;
--
--   -- o que já foi medido na L5 continua lá:
--   select count(*) from public.leituras l
--     join public.parametros p on p.id = l.parametro_id
--    where p.nome = 'Volume de produção L5';
-- =============================================================
