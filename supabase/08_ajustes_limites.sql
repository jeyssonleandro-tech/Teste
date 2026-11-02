-- =============================================================
-- Ajustes na lista de limites
-- Rodar UMA VEZ, depois do 07_limites.sql.
--
--   • Cloro Semi passa a ppm
--   • os parâmetros da ETE Industrial passam a alarmar por DIA,
--     em vez de pela média da semana
-- =============================================================

-- -------------------------------------------------------------
-- 1) Cloro Semi: ppm
--    Para água, ppm e mg/L dão o mesmo número. O que muda é o
--    rótulo — e ele tem que bater com o que a equipe usa em campo.
-- -------------------------------------------------------------
update public.parametros
   set unidade_medida = 'ppm'
 where nome = 'Cloro Semi' and aplica_a_tipo = 'ETA';

-- -------------------------------------------------------------
-- 2) ETE Industrial alarma por dia
--    Antes, a comparação era contra a média da semana: uma semana
--    com média dentro da faixa escondia o dia que saiu. Agora o
--    painel olha o pior dia do período.
--
--    O número exibido continua sendo a média — o que muda é a
--    pergunta que dispara o alerta.
-- -------------------------------------------------------------
update public.parametros
   set limite_base = 'diario'
 where aplica_a_tipo = 'ETE Industrial'
   and (limite_inferior is not null or limite_superior is not null);

-- 'Água Cervejaria' e 'Água XS' seguem com o mesmo teto de 1.600 m³/d,
-- confirmado pelo supervisor — não é duplicidade de digitação.

-- =============================================================
-- CONFERINDO
--   select aplica_a_tipo, nome, unidade_medida, agregacao,
--          limite_inferior, limite_superior, limite_base
--     from public.parametros
--    where limite_inferior is not null or limite_superior is not null
--    order by aplica_a_tipo, ordem;
-- =============================================================
