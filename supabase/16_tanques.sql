-- =============================================================
-- Nível dos tanques — o que o supervisório mostra, no painel
-- Rodar UMA VEZ, depois do 15_ajuste_indice_agua.sql.
-- Idempotente: rodar de novo não duplica nada.
--
-- Três tanques passam a ser lançados ao fim de cada turno:
--   • TQ Químico       (ETE Industrial)
--   • TQ Equalização   (ETE Industrial)
--   • TQ Equalização   (ETE Sanitária)
--
-- A unidade de medida é '%' — é o que o supervisório apresenta
-- (LIT-962-1, LIT-962-2) e é o que o operador lê na tela. Se um dia a
-- leitura passar a ser em m3, basta trocar 'unidade_medida' aqui e
-- informar a capacidade do tanque em 'limite_superior': o desenho usa
-- esse valor como topo da escala.
--
-- Agregação 'ultimo': nível não se soma nem se tira média. O valor do
-- dia é o do último turno lançado; o da semana, o do último dia.
-- =============================================================

-- -------------------------------------------------------------
-- 1) Uma coluna diz quais parâmetros o painel desenha como tanque
--    Sem isso o painel precisaria reconhecer tanque pelo nome, e um
--    parâmetro novo dependeria de mexer no HTML.
-- -------------------------------------------------------------
alter table public.parametros
  add column if not exists e_tanque boolean not null default false;

comment on column public.parametros.e_tanque is
  'true = o painel desenha este parâmetro como tanque, além da série.';

-- -------------------------------------------------------------
-- 2) Os três níveis
-- -------------------------------------------------------------
insert into public.parametros
  (nome, unidade_medida, aplica_a_tipo, ordem, agregacao, periodicidade, e_tanque) values
  ('Nível TQ Químico',     '%', 'ETE Industrial', 12, 'ultimo', 'diario', true),
  ('Nível TQ Equalização', '%', 'ETE Industrial', 14, 'ultimo', 'diario', true),
  ('Nível TQ Equalização', '%', 'ETE Sanitária',  12, 'ultimo', 'diario', true)
on conflict (nome, aplica_a_tipo) do update
   set unidade_medida = excluded.unidade_medida,
       ordem          = excluded.ordem,
       agregacao      = excluded.agregacao,
       periodicidade  = excluded.periodicidade,
       e_tanque       = true,
       ativo          = true;

-- =============================================================
-- CONFERINDO
--   select nome, aplica_a_tipo, unidade_medida, agregacao, e_tanque
--     from public.parametros where e_tanque order by aplica_a_tipo, ordem;
--
--   -- os níveis lançados, turno a turno:
--   select unidade, parametro, periodo, turno, valor
--     from public.vw_turnos
--    where granularidade = 'diario' and parametro like 'Nível%'
--    order by periodo desc, unidade, turno limit 20;
-- =============================================================
