-- =============================================================
-- Quais parâmetros entram na apresentação
-- Rodar UMA VEZ, depois do 21_teto_e_l5.sql. Idempotente.
--
-- A apresentação é para a diretoria; o painel é para a operação. Nem
-- tudo que a operação acompanha todo dia merece um slide. Esta coluna
-- separa as duas coisas — e o próprio botão "Editar" da apresentação
-- grava aqui, então a lista deixa de depender de mim.
--
-- Saem agora, a pedido da operação:
--   ETA            — Turbidez, Cloro Semi
--   ETE Industrial — os dois níveis de tanque, pH Elev. Orgânico
-- =============================================================

alter table public.parametros
  add column if not exists exibir_na_apresentacao boolean not null default true;

comment on column public.parametros.exibir_na_apresentacao is
  'false = o parâmetro fica no painel, mas fora dos slides do mês.';

update public.parametros
   set exibir_na_apresentacao = false
 where (aplica_a_tipo = 'ETA' and nome in ('Turbidez', 'Cloro Semi'))
    or (aplica_a_tipo = 'ETE Industrial'
        and nome in ('Nível TQ Químico', 'Nível TQ Equalização', 'pH Elev. Orgânico'));

-- =============================================================
-- CONFERINDO
--   select aplica_a_tipo, nome, exibir_no_painel, exibir_na_apresentacao
--     from public.parametros
--    where ativo and not exibir_na_apresentacao
--    order by aplica_a_tipo, ordem;
-- =============================================================
