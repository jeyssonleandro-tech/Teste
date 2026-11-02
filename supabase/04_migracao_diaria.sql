-- =============================================================
-- Migração: lançamento semanal → diário + formulário com login
-- Rodar UMA VEZ, depois dos scripts 01, 02 e 03.
--
-- O que muda:
--   • leituras_semanais  →  leituras   (uma linha por DIA)
--   • coluna 'semana'    →  'data'
--   • cada parâmetro ganha uma regra de agregação semanal
--   • passa a registrar QUEM lançou (uso interno, fora do painel)
--   • o painel lê uma view que agrega os dias em semanas
-- =============================================================

-- -------------------------------------------------------------
-- 1) Renomeia a tabela e a coluna
--    Só renomeia o que ainda não foi renomeado, para o script poder
--    ser rodado de novo sem quebrar no meio.
-- -------------------------------------------------------------
do $$
begin
  if to_regclass('public.leituras_semanais') is not null
     and to_regclass('public.leituras') is null then
    alter table public.leituras_semanais rename to leituras;
  end if;

  if to_regclass('public.leituras') is null then
    raise exception
      'A tabela de leituras não existe. Rode antes o 01_schema.sql.';
  end if;

  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'leituras'
               and column_name = 'semana') then
    alter table public.leituras rename column semana to data;
  end if;
end $$;

comment on table public.leituras is 'Uma linha por unidade + parâmetro + dia.';
comment on column public.leituras.data is 'Dia da medição.';

-- Uma medição por unidade + parâmetro + dia
alter table public.leituras drop constraint if exists leitura_unica_por_semana;
alter table public.leituras add constraint leitura_unica_por_dia
  unique (unidade_id, parametro_id, data);

-- -------------------------------------------------------------
-- 2) Quem lançou (rastreabilidade interna)
--    ATENÇÃO LGPD: é dado pessoal. Fica fora das views públicas.
-- -------------------------------------------------------------
alter table public.leituras
  add column if not exists registrado_por uuid default auth.uid() references auth.users(id);

comment on column public.leituras.registrado_por is
  'Usuário que lançou. Dado pessoal — nunca expor nas views públicas.';

-- -------------------------------------------------------------
-- 3) Regra de agregação semanal de cada parâmetro
-- -------------------------------------------------------------
alter table public.parametros
  add column if not exists agregacao text not null default 'media'
  check (agregacao in ('media', 'soma', 'ultimo'));

comment on column public.parametros.agregacao is
  'Como os dias viram semana: media | soma | ultimo valor do período.';

update public.parametros set agregacao = 'soma'
  where nome in ('Volume tratado', 'Vol Tratado', 'Pluviometria');

update public.parametros set agregacao = 'ultimo'
  where nome in ('Régua linimétrica');

-- Os demais (DQO, pH, Acidez, Vazões, Turbidez, Cloro) ficam em 'media'.

-- -------------------------------------------------------------
-- 4) Views do painel
-- -------------------------------------------------------------

-- 4.1) Visão diária — o detalhe, para investigar
drop view if exists public.vw_dashboard;
drop view if exists public.vw_leituras_diarias;

create view public.vw_leituras_diarias
with (security_invoker = on) as
select
  l.id,
  u.nome            as unidade,
  u.tipo            as tipo_unidade,
  p.nome            as parametro,
  p.unidade_medida,
  p.ordem           as ordem_parametro,
  l.data,
  l.valor,
  l.observacao
from public.leituras l
join public.unidades   u on u.id = l.unidade_id
join public.parametros p on p.id = l.parametro_id
where u.ativo and p.ativo;

comment on view public.vw_leituras_diarias is
  'Leituras dia a dia. Sem a coluna registrado_por — não expor dado pessoal.';

-- 4.2) Visão semanal — o que o painel mostra por padrão.
--      A semana é identificada pela segunda-feira (date_trunc 'week').
create view public.vw_dashboard
with (security_invoker = on) as
select
  u.nome  as unidade,
  u.tipo  as tipo_unidade,
  p.nome  as parametro,
  p.unidade_medida,
  p.ordem as ordem_parametro,
  p.agregacao,
  date_trunc('week', l.data)::date as semana,
  count(l.valor)                   as dias_lancados,
  case p.agregacao
    when 'soma'   then sum(l.valor)
    when 'ultimo' then (array_agg(l.valor order by l.data desc))[1]
    else               avg(l.valor)
  end as valor
from public.leituras l
join public.unidades   u on u.id = l.unidade_id
join public.parametros p on p.id = l.parametro_id
where u.ativo and p.ativo and l.valor is not null
group by u.nome, u.tipo, p.nome, p.unidade_medida, p.ordem, p.agregacao,
         date_trunc('week', l.data);

comment on view public.vw_dashboard is
  'Leituras agregadas por semana, conforme a regra de cada parâmetro.';

-- -------------------------------------------------------------
-- 5) Permissões
-- -------------------------------------------------------------
grant select on public.vw_dashboard          to anon, authenticated;
grant select on public.vw_leituras_diarias   to anon, authenticated;

-- Escrita: quem tem login pode lançar e corrigir, mas NÃO apagar.
-- Apagar continua possível só pelo painel do Supabase, com a sua conta.
drop policy if exists "escrita autenticada leituras" on public.leituras;

drop policy if exists "lancamento autenticado" on public.leituras;
create policy "lancamento autenticado"
  on public.leituras for insert
  to authenticated
  with check (true);

drop policy if exists "correcao autenticada" on public.leituras;
create policy "correcao autenticada"
  on public.leituras for update
  to authenticated
  using (true) with check (true);

-- =============================================================
-- CONFERINDO
--   select nome, agregacao from public.parametros order by nome;
--   select * from public.vw_dashboard limit 5;
-- =============================================================
