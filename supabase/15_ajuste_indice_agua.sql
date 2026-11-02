-- =============================================================
-- Ajuste do Índice de Água — água mineral no numerador
-- Rodar UMA VEZ, depois do 14_indice_agua.sql.
-- Idempotente: rodar de novo não duplica nada.
--
-- O que muda:
--
--   1. 'Volume Tratado' (ETA) passa a se chamar 'Volume FIT 100'.
--      Só o da ETA — a ETE Industrial e a ETE Sanitária têm um
--      parâmetro de mesmo nome, que continua como está.
--
--   2. Entra 'Volume Andina 1' (ETA, m3): a água mineral, que faltava
--      no numerador. Insumo oculto, como o Caminhão Pipa.
--
--   3. 'Vazão de Entrada' (ETA) sai de cena.
--
--   4. O Índice de Água passa a ser:
--
--        (Volume FIT 100 + Caminhão Pipa + Volume Andina 1)
--        ------------------------------------------------
--                 Volume de produção × 5,678
--
--      O Índice de Água Cervejaria não muda.
--
-- SOBRE O 5,678: a fórmula veio escrita como "/ volume de produção",
-- sem o fator. Ele foi mantido porque a produção é lançada em CXU e o
-- índice é L/L: sem converter caixa em litro o resultado sairia 5,678
-- vezes maior — perto de 7, contra um teto de 1,33. Se a intenção era
-- mesmo tirar o fator, é uma linha nesta view.
-- =============================================================

-- -------------------------------------------------------------
-- 1) Renomear — o histórico já lançado acompanha
--    'leituras' aponta para o id do parâmetro, não para o nome:
--    tudo o que já foi medido continua ligado ao mesmo registro.
-- -------------------------------------------------------------
update public.parametros
   set nome = 'Volume FIT 100'
 where nome = 'Volume Tratado' and aplica_a_tipo = 'ETA';

-- -------------------------------------------------------------
-- 2) A água mineral entra como insumo oculto
-- -------------------------------------------------------------
insert into public.parametros
  (nome, unidade_medida, aplica_a_tipo, ordem, agregacao,
   exibir_no_painel, calculado) values
  ('Volume Andina 1', 'm3', 'ETA', 91, 'soma', false, false)
on conflict (nome, aplica_a_tipo) do update
   set unidade_medida   = excluded.unidade_medida,
       ordem            = excluded.ordem,
       agregacao        = excluded.agregacao,
       exibir_no_painel = excluded.exibir_no_painel,
       calculado        = excluded.calculado,
       ativo            = true;

-- -------------------------------------------------------------
-- 3) 'Vazão de Entrada' sai do formulário, do painel e da planilha
--    Desativar em vez de apagar: o que já foi medido continua no
--    banco e volta a aparecer com um 'ativo = true' se um dia fizer
--    falta. Apagar exigiria destruir as leituras junto.
-- -------------------------------------------------------------
update public.parametros
   set ativo = false
 where nome = 'Vazão de Entrada' and aplica_a_tipo = 'ETA';

-- -------------------------------------------------------------
-- 4) O cálculo, com o numerador novo
--    'create or replace' preserva as views do dashboard que
--    dependem desta — as colunas são exatamente as mesmas.
-- -------------------------------------------------------------
create or replace view public.vw_indice_agua
with (security_invoker = on) as
with insumos as (
  select
    l.data,
    sum(l.valor) filter (
      where u.tipo = 'ETA'
        and p.nome in ('Volume FIT 100', 'Caminhão Pipa', 'Volume Andina 1')
    ) as agua_total_m3,
    sum(l.valor) filter (
      where u.tipo = 'ETA' and p.nome = 'Água Cervejaria'
    ) as agua_cervejaria_m3,
    sum(l.valor) filter (
      where p.nome = 'Volume de produção'
    ) as producao_cxu,
    sum(l.valor) filter (
      where p.nome = 'Volume de produção L5'
    ) as producao_l5_cxu
  from public.leituras l
  join public.unidades   u on u.id = l.unidade_id
  join public.parametros p on p.id = l.parametro_id
  where u.ativo and p.ativo and l.valor is not null
  group by l.data
),
-- Cada índice vira um par (água, produção) do dia. Um índice novo é
-- mais uma linha aqui — o resto da view não muda.
por_dia as (
  select 'Índice de Água'::text as parametro, data,
         agua_total_m3 as agua_m3, producao_cxu as producao_cxu
    from insumos
  union all
  select 'Índice de Água Cervejaria', data,
         agua_cervejaria_m3, producao_l5_cxu
    from insumos
),
-- Só entram os dias com os dois lados lançados. Um dia com água mas
-- sem produção somaria água ao numerador da semana sem somar nada ao
-- denominador, e inflaria o índice do período inteiro por causa de um
-- lançamento em falta. Melhor a semana pesar menos dias e estar certa.
validos as (
  select * from por_dia
   where agua_m3 is not null and coalesce(producao_cxu, 0) > 0
),
periodos as (
  select 'diario'::text as granularidade, parametro, data as periodo,
         agua_m3, producao_cxu
    from validos
  union all
  select 'semanal', parametro, date_trunc('week', data)::date,
         sum(agua_m3), sum(producao_cxu)
    from validos group by parametro, date_trunc('week', data)
  union all
  select 'mensal', parametro, date_trunc('month', data)::date,
         sum(agua_m3), sum(producao_cxu)
    from validos group by parametro, date_trunc('month', data)
)
select
  granularidade,
  parametro,
  periodo,
  round((agua_m3 * 1000) / (producao_cxu * 5.678), 3) as valor,
  agua_m3,
  producao_cxu
from periodos;

comment on view public.vw_indice_agua is
  'Os índices de água por dia, semana e mês. Cada período divide a soma '
  'da água pela soma da produção — razão nunca se agrega por média.';

-- =============================================================
-- CONFERINDO
--   -- o que a ETA pede hoje, e o que fica oculto:
--   select nome, unidade_medida, ordem, exibir_no_painel, calculado
--     from public.parametros
--    where aplica_a_tipo = 'ETA' and ativo order by ordem;
--
--   -- 'Vazão de Entrada' deve aparecer aqui, e só aqui:
--   select nome, aplica_a_tipo from public.parametros where not ativo;
--
--   -- os índices, dia a dia:
--   select * from public.vw_indice_agua
--    where granularidade = 'diario' order by periodo desc, parametro limit 20;
-- =============================================================
