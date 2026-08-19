-- =============================================================
-- Dashboard de Estações de Tratamento — Estrutura das tabelas
-- Rodar UMA VEZ, no SQL Editor do Supabase (menu lateral → SQL Editor).
-- =============================================================

-- -------------------------------------------------------------
-- 1) UNIDADES — cadastro de cada ativo (ETE, ETA, Represa...)
-- -------------------------------------------------------------
create table if not exists public.unidades (
  id            bigint generated always as identity primary key,
  nome          text not null unique,
  tipo          text not null,
  localizacao   text,                 -- reservado: futuro link com planta baixa
  capacidade    numeric,              -- capacidade nominal (opcional)
  unidade_capacidade text,            -- ex.: 'm3/dia'
  ativo         boolean not null default true,
  criado_em     timestamptz not null default now()
);

comment on table public.unidades is 'Cadastro das unidades operacionais. Uma linha por estação/represa.';
comment on column public.unidades.tipo is 'ETE Industrial | ETE Sanitária | ETA | Represa';

-- -------------------------------------------------------------
-- 2) PARAMETROS — catálogo dos indicadores que podem ser medidos
-- -------------------------------------------------------------
create table if not exists public.parametros (
  id             bigint generated always as identity primary key,
  nome           text not null unique,
  unidade_medida text,                -- ex.: 'mg/L', 'm3/h', 'NTU'
  aplica_a_tipo  text,                -- a qual tipo de unidade se aplica (informativo)
  ordem          integer not null default 0,   -- ordem de exibição no dashboard
  ativo          boolean not null default true
);

comment on table public.parametros is 'Catálogo de indicadores. Novo indicador = uma linha nova aqui, sem alterar estrutura.';

-- -------------------------------------------------------------
-- 3) LEITURAS_SEMANAIS — o lançamento de cada semana
-- -------------------------------------------------------------
create table if not exists public.leituras_semanais (
  id           bigint generated always as identity primary key,
  unidade_id   bigint not null references public.unidades(id)   on delete restrict,
  parametro_id bigint not null references public.parametros(id) on delete restrict,
  semana       date   not null,       -- convenção: segunda-feira da semana de referência
  valor        numeric,
  observacao   text,
  criado_em    timestamptz not null default now(),
  constraint leitura_unica_por_semana unique (unidade_id, parametro_id, semana)
);

comment on table public.leituras_semanais is 'Uma linha por unidade + parâmetro + semana.';
comment on column public.leituras_semanais.semana is 'Usar sempre a segunda-feira da semana de referência.';

create index if not exists idx_leituras_semana   on public.leituras_semanais (semana desc);
create index if not exists idx_leituras_unidade  on public.leituras_semanais (unidade_id, semana desc);

-- -------------------------------------------------------------
-- 4) OCORRENCIAS — eventos fora do padrão (opcional, mas útil)
-- -------------------------------------------------------------
create table if not exists public.ocorrencias (
  id         bigint generated always as identity primary key,
  unidade_id bigint not null references public.unidades(id) on delete restrict,
  data       date not null,
  tipo       text,                    -- Manutenção | Parada | Não-conformidade...
  descricao  text,
  resolvido  boolean not null default false,
  criado_em  timestamptz not null default now()
);

comment on column public.ocorrencias.descricao is
  'ATENÇÃO LGPD: não escrever nomes, CPF ou contatos de pessoas neste campo.';

-- -------------------------------------------------------------
-- 5) VIEW usada pelo dashboard (já com os nomes resolvidos)
-- -------------------------------------------------------------
create or replace view public.vw_dashboard
with (security_invoker = on) as
select
  l.id,
  u.nome            as unidade,
  u.tipo            as tipo_unidade,
  p.nome            as parametro,
  p.unidade_medida,
  p.ordem           as ordem_parametro,
  l.semana,
  l.valor,
  l.observacao
from public.leituras_semanais l
join public.unidades   u on u.id = l.unidade_id
join public.parametros p on p.id = l.parametro_id
where u.ativo and p.ativo;

comment on view public.vw_dashboard is
  'Camada pública de leitura. O HTML consulta esta view, nunca as tabelas cruas.';
