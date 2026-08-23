-- =============================================================
-- Fecha o painel: leitura só para quem tem login
-- Rodar UMA VEZ, depois do 05_parametros_v2.sql.
--
-- Por quê:
--   O painel vai ser publicado na internet (GitHub Pages). Enquanto a
--   chave 'anon' puder ler, qualquer pessoa que descobrir o endereço vê
--   os dados de processo da planta. Depois deste script, sem login o
--   painel não mostra nada — nem que alguém copie a chave do HTML.
--
-- Consequência: quem for apenas VER o painel também precisa de um
-- usuário criado em Authentication → Users.
-- =============================================================

-- -------------------------------------------------------------
-- 1) As views deixam de ser legíveis pela chave pública
-- -------------------------------------------------------------
revoke select on public.vw_dashboard        from anon;
revoke select on public.vw_leituras_diarias from anon;

grant select on public.vw_dashboard        to authenticated;
grant select on public.vw_leituras_diarias to authenticated;

-- -------------------------------------------------------------
-- 2) E as tabelas por trás delas também
--    As views usam security_invoker: valem as policies das tabelas
--    base. Se 'anon' continuasse podendo ler as tabelas, bastaria
--    consultá-las direto para contornar a view.
-- -------------------------------------------------------------
drop policy if exists "leitura publica unidades" on public.unidades;
create policy "leitura autenticada unidades"
  on public.unidades for select to authenticated using (true);

drop policy if exists "leitura publica parametros" on public.parametros;
create policy "leitura autenticada parametros"
  on public.parametros for select to authenticated using (true);

drop policy if exists "leitura publica leituras" on public.leituras;
create policy "leitura autenticada leituras"
  on public.leituras for select to authenticated using (true);

drop policy if exists "leitura publica ocorrencias" on public.ocorrencias;
create policy "leitura autenticada ocorrencias"
  on public.ocorrencias for select to authenticated using (true);

-- =============================================================
-- CONFERINDO
--   select tablename, policyname, roles, cmd
--     from pg_policies where schemaname = 'public' order by tablename;
--   Nenhuma linha deve trazer 'anon' na coluna roles.
-- =============================================================
