-- =============================================================
-- Importação de leituras em lote, a partir de planilha
-- Rodar UMA VEZ. Depois é só reutilizar a cada importação.
--
-- Por que uma tabela de recepção em vez de importar direto:
--   'leituras' guarda unidade_id e parametro_id — códigos internos.
--   A planilha traz nomes. A recepção aceita texto cru, e a função
--   traduz, valida e move — reportando o que não bateu em vez de
--   deixar a linha sumir sem aviso.
-- =============================================================

-- -------------------------------------------------------------
-- 1) Tabela de recepção — tudo texto, para nada ser recusado na
--    importação do CSV. A validação acontece depois, com relatório.
-- -------------------------------------------------------------
create table if not exists public.importacao_leituras (
  linha       bigserial primary key,
  data        text,
  unidade     text,
  parametro   text,
  valor       text,
  observacao  text
);

comment on table public.importacao_leituras is
  'Área de recepção da importação em lote. Esvaziar depois de importar.';

alter table public.importacao_leituras enable row level security;

drop policy if exists "recepcao autenticada" on public.importacao_leituras;
create policy "recepcao autenticada"
  on public.importacao_leituras for all
  to authenticated using (true) with check (true);

-- -------------------------------------------------------------
-- 2) A função que traduz, valida e move
--
--    Aceita data em 03/08/2026 ou 2026-08-03, e número com vírgula
--    ou ponto decimal — é o que sai do Excel brasileiro e do Sheets.
--
--    Linha já existente para a mesma unidade + parâmetro + dia é
--    ATUALIZADA, não duplicada: reimportar corrige em vez de sujar.
-- -------------------------------------------------------------
create or replace function public.importar_leituras()
returns table (situacao text, linhas bigint, exemplos text)
language plpgsql
security invoker
as $$
declare
  gravadas bigint;
begin
  create temp table _norm on commit drop as
  select
    i.linha,
    nullif(trim(i.unidade), '')   as unidade,
    nullif(trim(i.parametro), '') as parametro,
    case
      when trim(i.data) ~ '^\d{4}-\d{1,2}-\d{1,2}$'  then to_date(trim(i.data), 'YYYY-MM-DD')
      when trim(i.data) ~ '^\d{1,2}/\d{1,2}/\d{4}$'  then to_date(trim(i.data), 'DD/MM/YYYY')
      else null
    end as data,
    case
      when trim(i.valor) is null or trim(i.valor) = '' then null
      -- com vírgula, o ponto é separador de milhar: 1.234,5 -> 1234.5
      when replace(replace(trim(i.valor), '.', ''), ',', '.') ~ '^-?\d+(\.\d+)?$'
           and trim(i.valor) like '%,%'
        then replace(replace(trim(i.valor), '.', ''), ',', '.')::numeric
      when trim(i.valor) ~ '^-?\d+(\.\d+)?$' then trim(i.valor)::numeric
      else null
    end as valor,
    nullif(trim(coalesce(i.observacao, '')), '') as observacao,
    trim(i.data) as data_crua, trim(i.valor) as valor_cru
  from public.importacao_leituras i;

  create temp table _resolvida on commit drop as
  select n.*, u.id as unidade_id, p.id as parametro_id
  from _norm n
  left join public.unidades u
         on lower(u.nome) = lower(n.unidade) and u.ativo
  left join public.parametros p
         on lower(p.nome) = lower(n.parametro) and p.ativo
        and (p.aplica_a_tipo is null or p.aplica_a_tipo = u.tipo);

  insert into public.leituras (unidade_id, parametro_id, data, valor, observacao)
  select unidade_id, parametro_id, data, valor, observacao
    from _resolvida
   where unidade_id is not null and parametro_id is not null
     and data is not null and valor is not null
  on conflict (unidade_id, parametro_id, data) do update
     set valor = excluded.valor,
         observacao = coalesce(excluded.observacao, public.leituras.observacao);

  get diagnostics gravadas = row_count;

  return query
  select 'gravadas'::text, gravadas,
         'linhas inseridas ou corrigidas em leituras'::text
  union all
  select 'data inválida', count(*),
         coalesce(string_agg(distinct data_crua, ' | ' order by data_crua), '')
    from _resolvida where data is null
   having count(*) > 0
  union all
  select 'valor inválido', count(*),
         coalesce(string_agg(distinct valor_cru, ' | ' order by valor_cru), '')
    from _resolvida where data is not null and valor is null
   having count(*) > 0
  union all
  select 'unidade não encontrada', count(*),
         coalesce(string_agg(distinct unidade, ' | ' order by unidade), '')
    from _resolvida where unidade_id is null
   having count(*) > 0
  union all
  select 'parâmetro não encontrado nessa unidade', count(*),
         coalesce(string_agg(distinct parametro || ' (' || coalesce(unidade,'?') || ')',
                             ' | ' order by parametro || ' (' || coalesce(unidade,'?') || ')'), '')
    from _resolvida where unidade_id is not null and parametro_id is null
   having count(*) > 0;
end $$;

comment on function public.importar_leituras() is
  'Traduz, valida e move a recepção para leituras. Devolve relatório.';

-- =============================================================
-- COMO USAR
--   1. Table Editor → importacao_leituras → Import data from CSV
--   2. select * from public.importar_leituras();
--   3. Confira o relatório. Corrija o que não bateu e repita se preciso.
--   4. Esvazie a recepção:  truncate public.importacao_leituras;
-- =============================================================
