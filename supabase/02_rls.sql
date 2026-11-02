-- =============================================================
-- Regras de acesso (RLS) — rodar DEPOIS do 01_schema.sql
--
-- Resultado esperado:
--   • chave pública (anon), usada pelo HTML  -> SÓ LEITURA
--   • usuário autenticado (você)             -> leitura + escrita
--   • ninguém de fora consegue inserir, editar ou apagar
-- =============================================================

-- 1) Liga o "cofre": sem policy, ninguém enxerga nada.
alter table public.unidades          enable row level security;
alter table public.parametros        enable row level security;
alter table public.leituras_semanais enable row level security;
alter table public.ocorrencias       enable row level security;

-- 2) LEITURA PÚBLICA (é o que faz o dashboard funcionar)
drop policy if exists "leitura publica unidades" on public.unidades;
create policy "leitura publica unidades"
  on public.unidades for select
  to anon, authenticated
  using (true);

drop policy if exists "leitura publica parametros" on public.parametros;
create policy "leitura publica parametros"
  on public.parametros for select
  to anon, authenticated
  using (true);

drop policy if exists "leitura publica leituras" on public.leituras_semanais;
create policy "leitura publica leituras"
  on public.leituras_semanais for select
  to anon, authenticated
  using (true);

drop policy if exists "leitura publica ocorrencias" on public.ocorrencias;
create policy "leitura publica ocorrencias"
  on public.ocorrencias for select
  to anon, authenticated
  using (true);

-- 3) ESCRITA: somente usuário autenticado.
--    Repare que 'anon' NÃO aparece em nenhuma policy abaixo —
--    por isso a chave pública do site não consegue gravar nada.
drop policy if exists "escrita autenticada unidades" on public.unidades;
create policy "escrita autenticada unidades"
  on public.unidades for all
  to authenticated
  using (true) with check (true);

drop policy if exists "escrita autenticada parametros" on public.parametros;
create policy "escrita autenticada parametros"
  on public.parametros for all
  to authenticated
  using (true) with check (true);

drop policy if exists "escrita autenticada leituras" on public.leituras_semanais;
create policy "escrita autenticada leituras"
  on public.leituras_semanais for all
  to authenticated
  using (true) with check (true);

drop policy if exists "escrita autenticada ocorrencias" on public.ocorrencias;
create policy "escrita autenticada ocorrencias"
  on public.ocorrencias for all
  to authenticated
  using (true) with check (true);

-- 4) Permissões de tabela para a view pública do dashboard
grant select on public.vw_dashboard to anon, authenticated;

-- =============================================================
-- COMO CONFERIR SE FICOU CERTO
--   Table Editor → abrir a tabela → o cadeado deve mostrar "RLS enabled".
--   Authentication → Policies → devem aparecer 2 policies por tabela.
-- =============================================================
