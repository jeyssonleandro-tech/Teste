-- =============================================================
-- Permitir excluir um usuário sem perder as leituras dele
-- Rodar UMA VEZ, depois do 08_ajustes_limites.sql.
--
-- O problema:
--   'leituras.registrado_por' aponta para auth.users sem dizer o que
--   fazer quando o usuário some. O padrão do Postgres é RECUSAR a
--   exclusão — daí o "Database error deleting user" no painel do
--   Supabase, que não explica nada.
--
-- A decisão:
--   a leitura sobrevive; o rastro de quem lançou é que se perde.
--   O dado de processo é o que não pode sumir. Saber quem digitou
--   serve para tirar dúvida recente, não para guardar para sempre —
--   e, sob a LGPD, não guardar dado pessoal a mais é o certo.
-- =============================================================

do $$
declare
  nome_fk text;
begin
  select conname into nome_fk
    from pg_constraint
   where conrelid = 'public.leituras'::regclass
     and contype = 'f'
     and pg_get_constraintdef(oid) like '%registrado_por%';

  if nome_fk is not null then
    execute format('alter table public.leituras drop constraint %I', nome_fk);
  end if;
end $$;

alter table public.leituras
  add constraint leituras_registrado_por_fkey
  foreign key (registrado_por) references auth.users(id) on delete set null;

comment on column public.leituras.registrado_por is
  'Usuário que lançou. Dado pessoal — nunca expor nas views públicas. '
  'Fica nulo se o usuário for excluído; a leitura permanece.';

-- =============================================================
-- CONFERINDO
--   select pg_get_constraintdef(oid)
--     from pg_constraint
--    where conrelid = 'public.leituras'::regclass and contype = 'f';
--   Deve aparecer ON DELETE SET NULL na linha do registrado_por.
-- =============================================================
