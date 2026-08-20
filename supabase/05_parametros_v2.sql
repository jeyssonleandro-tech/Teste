-- =============================================================
-- Ampliação do cadastro de parâmetros
-- Rodar UMA VEZ, depois do 04_migracao_diaria.sql.
--
-- O que muda:
--   • o mesmo nome de parâmetro passa a poder existir em tipos de
--     unidade diferentes, cada um com sua regra de agregação
--   • um parâmetro pode exibir DUAS agregações (ex.: total da semana
--     e média diária) sem o operador digitar o valor duas vezes
--   • nova unidade: Produção
--   • novos parâmetros da ETA, ETE Sanitária e ETE Industrial
--   • Acidez do reator corrigida
-- =============================================================

-- -------------------------------------------------------------
-- 1) Nome único por TIPO DE UNIDADE, não por projeto inteiro
--    Sem isso, 'Volume Tratado' da ETA impediria o da ETE Industrial.
-- -------------------------------------------------------------
alter table public.parametros drop constraint if exists parametros_nome_key;

drop index if exists parametros_nome_tipo_key;
create unique index parametros_nome_tipo_key
  on public.parametros (nome, aplica_a_tipo) nulls not distinct;

-- -------------------------------------------------------------
-- 2) Segunda agregação opcional
--    Ex.: volume com 'soma' (total da semana) e 'media' (média diária).
-- -------------------------------------------------------------
alter table public.parametros
  add column if not exists agregacao_extra text
  check (agregacao_extra in ('media', 'soma', 'ultimo'));

comment on column public.parametros.agregacao_extra is
  'Agregação adicional exibida como uma linha própria no painel. '
  'O lançamento continua sendo um só.';

-- -------------------------------------------------------------
-- 3) Correções no que já existia
-- -------------------------------------------------------------

-- 'Vol Tratado' (ETA) e 'Volume tratado' (ETE) passam a ter o mesmo
-- nome da nova lista. São os mesmos indicadores — renomear evita
-- dois campos parecidos na tela de lançamento.
update public.parametros
   set nome = 'Volume Tratado'
 where nome = 'Vol Tratado' and aplica_a_tipo = 'ETA';

update public.parametros
   set nome = 'Volume Tratado', agregacao = 'soma', agregacao_extra = 'media'
 where nome = 'Volume tratado' and aplica_a_tipo = 'ETE';

-- Acidez do reator: nome, unidade e agregação corrigidos
update public.parametros
   set nome = 'Acidez Reator', unidade_medida = 'mgHAc/L', agregacao = 'ultimo'
 where nome = 'Acidez do reator';

-- -------------------------------------------------------------
-- 4) Nova unidade
-- -------------------------------------------------------------
insert into public.unidades (nome, tipo) values ('Produção', 'Produção')
on conflict (nome) do nothing;

-- -------------------------------------------------------------
-- 5) Novos parâmetros
-- -------------------------------------------------------------
insert into public.parametros (nome, unidade_medida, aplica_a_tipo, ordem, agregacao) values
  -- ETA
  ('Água Cervejaria',    'm3',      'ETA',            50,  'soma'),
  ('Água refrigerante',  'm3',      'ETA',            60,  'soma'),
  ('Água XS',            'm3',      'ETA',            70,  'soma'),
  ('Vazão de Entrada',   'm3/h',    'ETA',            80,  'media'),
  -- ETE Sanitária (análises laboratoriais, normalmente semanais)
  ('DQO Eflu Bruto',     'mg/L',    'ETE Sanitária',  80,  'ultimo'),
  ('DQO Eflu Tratado',   'mg/L',    'ETE Sanitária',  90,  'ultimo'),
  ('Nitrogênio',         'mg/L',    'ETE Sanitária',  100, 'ultimo'),
  ('Fósforo',            'mg/L',    'ETE Sanitária',  110, 'ultimo'),
  -- ETE Industrial
  ('DQO Eflu Tratado',   'mg/L',    'ETE Industrial', 80,  'media'),
  -- Produção
  ('Volume de produção', 'CXU',     'Produção',       10,  'soma')
on conflict (nome, aplica_a_tipo) do nothing;

-- PENDENTE: 'Índice de Água' (L/L, ETA) é calculado — entra quando a
-- fórmula estiver definida.

-- -------------------------------------------------------------
-- 6) View semanal, agora com a agregação extra
--    Cada parâmetro rende uma linha; quem tem agregacao_extra rende
--    uma segunda, com o rótulo entre parênteses.
-- -------------------------------------------------------------
drop view if exists public.vw_dashboard;

create view public.vw_dashboard
with (security_invoker = on) as
with agregado as (
  select
    u.nome  as unidade,
    u.tipo  as tipo_unidade,
    p.nome  as parametro,
    p.unidade_medida,
    p.ordem as ordem_parametro,
    p.agregacao,
    p.agregacao_extra,
    date_trunc('week', l.data)::date as semana,
    sum(l.valor)                             as v_soma,
    avg(l.valor)                             as v_media,
    (array_agg(l.valor order by l.data desc))[1] as v_ultimo
  from public.leituras l
  join public.unidades   u on u.id = l.unidade_id
  join public.parametros p on p.id = l.parametro_id
  where u.ativo and p.ativo and l.valor is not null
  group by u.nome, u.tipo, p.nome, p.unidade_medida, p.ordem,
           p.agregacao, p.agregacao_extra, date_trunc('week', l.data)
)
select unidade, tipo_unidade, parametro, unidade_medida, ordem_parametro,
       agregacao, semana,
       case agregacao when 'soma' then v_soma
                      when 'ultimo' then v_ultimo
                      else v_media end as valor
from agregado
union all
select unidade, tipo_unidade,
       parametro || case agregacao_extra
                      when 'soma'   then ' (total da semana)'
                      when 'media'  then ' (média diária)'
                      else               ' (último valor)' end,
       unidade_medida, ordem_parametro + 1,
       agregacao_extra, semana,
       case agregacao_extra when 'soma' then v_soma
                            when 'ultimo' then v_ultimo
                            else v_media end
from agregado
where agregacao_extra is not null;

comment on view public.vw_dashboard is
  'Leituras agregadas por semana. Parâmetros com agregacao_extra '
  'aparecem em duas linhas, a partir do mesmo lançamento.';

grant select on public.vw_dashboard to anon, authenticated;

-- =============================================================
-- CONFERINDO
--   select aplica_a_tipo, nome, unidade_medida, agregacao, agregacao_extra
--     from public.parametros where ativo order by aplica_a_tipo, ordem;
-- =============================================================
