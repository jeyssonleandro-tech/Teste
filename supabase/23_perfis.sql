-- =============================================================
-- Perfis de acesso: quem lê, quem lança, quem administra
-- Rodar UMA VEZ, depois do 22_apresentacao.sql. Idempotente.
--
-- ANTES DE RODAR: troque SEU-EMAIL-AQUI, mais abaixo, pelo e-mail da
-- conta que vai administrar. O script recusa rodar sem isso — ficar sem
-- administrador seria pior que não ter perfis.
--
-- Até hoje, quem tinha login podia gravar. Com a diretoria entrando no
-- painel, um clique errado apaga lançamento sem deixar rastro de quem
-- foi. Passam a existir três perfis:
--
--   leitor    — vê o painel e a apresentação. Não grava nada.
--   lancador  — o leitor, mais lançar e corrigir leitura e importar.
--   admin     — o lançador, mais mexer no cadastro (limites, o que
--               entra na apresentação, unidades e parâmetros).
--
-- Quem não tem perfil cadastrado é LEITOR. É o padrão seguro: um
-- usuário novo, criado às pressas, nasce sem poder estragar nada.
--
-- A regra vive no banco, não na tela. Esconder um botão não protege
-- coisa nenhuma — quem souber o endereço da API chama assim mesmo.
-- =============================================================

-- -------------------------------------------------------------
-- 1) A tabela de perfis
-- -------------------------------------------------------------
create table if not exists public.perfis (
  usuario_id uuid primary key references auth.users(id) on delete cascade,
  nome       text,
  papel      text not null default 'leitor'
             check (papel in ('leitor', 'lancador', 'admin')),
  criado_em  timestamptz not null default now()
);

comment on table public.perfis is
  'Um perfil por usuário. Sem linha aqui, o usuário é leitor.';

alter table public.perfis enable row level security;

-- -------------------------------------------------------------
-- 2) A função que diz o papel de quem está chamando
--    'security definer' para ler 'perfis' sem passar pela RLS da
--    própria tabela — sem isso, a política de perfis consultaria
--    perfis e entraria em recursão.
-- -------------------------------------------------------------
create or replace function public.meu_papel()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select papel from public.perfis where usuario_id = auth.uid()),
    'leitor')
$$;

comment on function public.meu_papel() is
  'Papel do usuário autenticado: leitor, lancador ou admin.';

revoke all on function public.meu_papel() from public;
grant execute on function public.meu_papel() to authenticated;

create or replace function public.pode_lancar()
returns boolean language sql stable as $$
  select public.meu_papel() in ('lancador', 'admin')
$$;

create or replace function public.pode_administrar()
returns boolean language sql stable as $$
  select public.meu_papel() = 'admin'
$$;

grant execute on function public.pode_lancar()      to authenticated;
grant execute on function public.pode_administrar() to authenticated;

-- -------------------------------------------------------------
-- 3) Cada um enxerga o próprio perfil; só o admin mexe na lista
-- -------------------------------------------------------------
drop policy if exists "leitura do proprio perfil" on public.perfis;
drop policy if exists "leitura do proprio perfil" on public.perfis;
create policy "leitura do proprio perfil"
  on public.perfis for select to authenticated
  using (usuario_id = auth.uid() or public.pode_administrar());

drop policy if exists "admin gerencia perfis" on public.perfis;
drop policy if exists "admin gerencia perfis" on public.perfis;
create policy "admin gerencia perfis"
  on public.perfis for all to authenticated
  using (public.pode_administrar()) with check (public.pode_administrar());

grant select on public.perfis to authenticated;
grant insert, update, delete on public.perfis to authenticated;

-- -------------------------------------------------------------
-- 4) Leitura: continua para todo mundo que tem login
--    (as políticas de select do 06 seguem valendo; ficam aqui só as
--     de escrita, que são as que mudam)
-- -------------------------------------------------------------

-- LEITURAS — lançar e corrigir viram privilégio de lançador
drop policy if exists "lancamento autenticado" on public.leituras;
drop policy if exists "lancamento por quem lanca" on public.leituras;
create policy "lancamento por quem lanca"
  on public.leituras for insert to authenticated
  with check (public.pode_lancar());

drop policy if exists "correcao autenticada" on public.leituras;
drop policy if exists "correcao por quem lanca" on public.leituras;
create policy "correcao por quem lanca"
  on public.leituras for update to authenticated
  using (public.pode_lancar()) with check (public.pode_lancar());

-- Apagar segue fora do alcance de todos: só pelo painel do Supabase.
drop policy if exists "escrita autenticada leituras" on public.leituras;

-- OCORRÊNCIAS — mesma regra
drop policy if exists "escrita autenticada ocorrencias" on public.ocorrencias;
drop policy if exists "ocorrencia por quem lanca" on public.ocorrencias;
create policy "ocorrencia por quem lanca"
  on public.ocorrencias for all to authenticated
  using (public.pode_lancar()) with check (public.pode_lancar());

-- RECEPÇÃO DA IMPORTAÇÃO — mesma regra
drop policy if exists "recepcao autenticada" on public.importacao_leituras;
drop policy if exists "recepcao por quem lanca" on public.importacao_leituras;
create policy "recepcao por quem lanca"
  on public.importacao_leituras for all to authenticated
  using (public.pode_lancar()) with check (public.pode_lancar());

-- CADASTRO — mexer em unidade e parâmetro é de administrador.
-- É aqui que moram limites, metas e o que entra na apresentação.
drop policy if exists "escrita autenticada unidades" on public.unidades;
drop policy if exists "cadastro de unidades pelo admin" on public.unidades;
create policy "cadastro de unidades pelo admin"
  on public.unidades for all to authenticated
  using (public.pode_administrar()) with check (public.pode_administrar());

drop policy if exists "escrita autenticada parametros" on public.parametros;
drop policy if exists "cadastro de parametros pelo admin" on public.parametros;
create policy "cadastro de parametros pelo admin"
  on public.parametros for all to authenticated
  using (public.pode_administrar()) with check (public.pode_administrar());

-- -------------------------------------------------------------
-- 5) Quem é quem, hoje
--    Todos os usuários que já existem viram LANÇADORES — é o que eles
--    vinham fazendo. O administrador é promovido em seguida.
-- -------------------------------------------------------------
insert into public.perfis (usuario_id, nome, papel)
select u.id, u.email, 'lancador'
  from auth.users u
 where not exists (select 1 from public.perfis p where p.usuario_id = u.id);

do $$
declare
  email_admin text := 'SEU-EMAIL-AQUI';
  alvo uuid;
begin
  select id into alvo from auth.users where lower(email) = lower(email_admin);
  if alvo is null then
    raise exception
      'Troque SEU-EMAIL-AQUI pelo e-mail do administrador antes de rodar. '
      'Sem administrador, ninguém poderia mais mexer no cadastro.';
  end if;
  update public.perfis set papel = 'admin' where usuario_id = alvo;
end $$;

-- =============================================================
-- CONFERINDO
--   select p.papel, p.nome, u.email
--     from public.perfis p join auth.users u on u.id = p.usuario_id
--    order by p.papel, u.email;
--
--   -- promover ou rebaixar alguém:
--   -- update public.perfis set papel = 'leitor'
--   --  where usuario_id = (select id from auth.users where email = 'fulano@empresa.com');
--
--   -- um usuário novo já nasce leitor; para deixá-lo lançar:
--   -- insert into public.perfis (usuario_id, nome, papel)
--   -- select id, email, 'lancador' from auth.users where email = 'novo@empresa.com'
--   -- on conflict (usuario_id) do update set papel = 'lancador';
-- =============================================================
