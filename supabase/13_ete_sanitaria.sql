-- =============================================================
-- ETE Sanitária: novos parâmetros e periodicidade
-- Rodar UMA VEZ, depois do 12_turnos.sql.
--
--   • Volume Tratado e Vazão de tratamento entram na ETE Sanitária
--   • DQO Eflu Bruto e Tratado seguem diários
--   • Nitrogênio e Fósforo passam a ser semanais
--   • a série por turno passa a carregar tudo que o alerta precisa
-- =============================================================

-- -------------------------------------------------------------
-- 1) Periodicidade esperada de cada parâmetro
--    Não muda o armazenamento — a leitura continua sendo do dia em
--    que foi feita. Serve para o formulário avisar o operador de que
--    aquele campo não é para preencher todo dia, e ele parar de achar
--    que esqueceu alguma coisa.
-- -------------------------------------------------------------
alter table public.parametros
  add column if not exists periodicidade text not null default 'diario'
  check (periodicidade in ('diario', 'semanal'));

comment on column public.parametros.periodicidade is
  'Com que frequência se espera o lançamento. Não restringe o banco.';

update public.parametros
   set periodicidade = 'semanal'
 where aplica_a_tipo = 'ETE Sanitária'
   and nome in ('Nitrogênio', 'Fósforo');

-- -------------------------------------------------------------
-- 2) Novos parâmetros da ETE Sanitária
--    Os nomes já existem noutras unidades — a unicidade é por nome +
--    tipo de unidade, então convivem sem conflito.
--    Ordem baixa: o que é operacional vem antes das análises.
-- -------------------------------------------------------------
insert into public.parametros
  (nome, unidade_medida, aplica_a_tipo, ordem, agregacao, periodicidade) values
  ('Volume Tratado',      'm3',   'ETE Sanitária', 10, 'soma',  'diario'),
  ('Vazão de tratamento', 'm3/h', 'ETE Sanitária', 20, 'media', 'diario')
on conflict (nome, aplica_a_tipo) do nothing;

-- -------------------------------------------------------------
-- 3) A série por turno passa a trazer o que o alerta precisa
--    Sem agregacao, limite_base e os extremos, ver um turno isolado
--    perderia a sinalização de fora de faixa que a visão consolidada
--    tem — e a tela mentiria por omissão.
-- -------------------------------------------------------------
drop view if exists public.vw_turnos;

create view public.vw_turnos
with (security_invoker = on) as
with base as (
  select
    u.nome  as unidade,
    u.tipo  as tipo_unidade,
    p.nome  as parametro,
    p.unidade_medida,
    p.ordem as ordem_parametro,
    p.agregacao,
    p.limite_inferior,
    p.limite_superior,
    p.limite_base,
    l.data,
    coalesce(l.turno, 1) as turno,
    l.valor
  from public.leituras l
  join public.unidades   u on u.id = l.unidade_id
  join public.parametros p on p.id = l.parametro_id
  where u.ativo and p.ativo and u.usa_turno and l.valor is not null
)
select 'diario' as granularidade, unidade, tipo_unidade, parametro, unidade_medida,
       ordem_parametro, agregacao, turno, data as periodo, valor,
       -- no dia, o próprio valor é o extremo do turno
       valor as valor_min_dia, valor as valor_max_dia,
       limite_inferior, limite_superior, limite_base
  from base
union all
select 'semanal', unidade, tipo_unidade, parametro, unidade_medida,
       ordem_parametro, agregacao, turno, date_trunc('week', data)::date,
       case agregacao when 'soma'   then sum(valor)
                      when 'ultimo' then (array_agg(valor order by data desc))[1]
                      else               avg(valor) end,
       min(valor), max(valor),
       limite_inferior, limite_superior, limite_base
  from base
 group by unidade, tipo_unidade, parametro, unidade_medida, ordem_parametro,
          agregacao, limite_inferior, limite_superior, limite_base,
          turno, date_trunc('week', data)
union all
select 'mensal', unidade, tipo_unidade, parametro, unidade_medida,
       ordem_parametro, agregacao, turno, date_trunc('month', data)::date,
       case agregacao when 'soma'   then sum(valor)
                      when 'ultimo' then (array_agg(valor order by data desc))[1]
                      else               avg(valor) end,
       min(valor), max(valor),
       limite_inferior, limite_superior, limite_base
  from base
 group by unidade, tipo_unidade, parametro, unidade_medida, ordem_parametro,
          agregacao, limite_inferior, limite_superior, limite_base,
          turno, date_trunc('month', data);

comment on view public.vw_turnos is
  'Série de um turno isolado, nas três granularidades, com limites e '
  'extremos — para a visão por turno alertar igual à consolidada.';

grant select on public.vw_turnos to authenticated;

-- =============================================================
-- CONFERINDO
--   select nome, unidade_medida, ordem, agregacao, periodicidade
--     from public.parametros
--    where aplica_a_tipo = 'ETE Sanitária' and ativo order by ordem;
-- =============================================================
