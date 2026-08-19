-- =============================================================
-- Cadastro inicial — rodar UMA VEZ, depois do 02_rls.sql
--
-- AJUSTE os nomes e localizações antes de rodar: os valores abaixo
-- são exemplos. Se preferir, pule este arquivo e cadastre pelo
-- Table Editor (veja docs/guia-lancamento-supabase.md).
-- =============================================================

-- -------------------------------------------------------------
-- UNIDADES (ajuste nome e localização para os reais)
-- -------------------------------------------------------------
insert into public.unidades (nome, tipo, localizacao) values
  ('ETE Industrial',  'ETE Industrial', 'ajustar'),
  ('ETE Sanitária',   'ETE Sanitária',  'ajustar'),
  ('ETA',             'ETA',            'ajustar'),
  ('Represa',         'Represa',        'ajustar')
on conflict (nome) do nothing;

-- -------------------------------------------------------------
-- PARAMETROS (acrescente/remova conforme o que você realmente mede)
-- 'ordem' controla a ordem das colunas no dashboard.
-- -------------------------------------------------------------
insert into public.parametros (nome, unidade_medida, aplica_a_tipo, ordem) values
  -- ETE
  ('DQO',                    'mg/L',  'ETE',     10),
  ('DBO',                    'mg/L',  'ETE',     20),
  ('pH',                     '-',     'ETE',     30),
  ('Acidez do reator',       'mg/L',  'ETE Industrial', 40),
  ('Volume tratado',         'm3',    'ETE',     50),
  -- ETA
  ('Volume do tanque',       'm3',    'ETA',     10),
  ('Vazão de tratamento',    'm3/h',  'ETA',     20),
  ('Vazão de captação',      'm3/h',  'ETA',     30),
  ('Turbidez',               'NTU',   'ETA',     40),
  -- Represa
  ('Nível do reservatório',  'm',     'Represa', 10)
on conflict (nome) do nothing;
