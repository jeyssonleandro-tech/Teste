-- =============================================================
-- Cadastro inicial — rodar UMA VEZ, depois do 02_rls.sql
-- =============================================================

-- -------------------------------------------------------------
-- UNIDADES
-- -------------------------------------------------------------
insert into public.unidades (nome, tipo, localizacao) values
  ('ETE Industrial', 'ETE Industrial', '1'),
  ('ETE Sanitária',  'ETE Sanitária',  '2'),
  ('ETA',            'ETA',            '3'),
  ('Represa',        'Represa',        '4')
on conflict (nome) do nothing;

-- -------------------------------------------------------------
-- PARAMETROS
-- 'ordem' controla a ordem das colunas no dashboard.
-- -------------------------------------------------------------
insert into public.parametros (nome, unidade_medida, aplica_a_tipo, ordem) values
  -- ETE
  ('DQO Equalizado',       'mg/L', 'ETE',            10),
  ('DQO Químico',          'mg/L', 'ETE',            20),
  ('pH Equalizado',        '-',    'ETE',            30),
  ('pH Químico',           '-',    'ETE',            40),
  ('pH Elev. Orgânico',    '-',    'ETE',            50),
  ('Acidez do reator',     'mg/L', 'ETE Industrial', 60),
  ('Volume tratado',       'm3',   'ETE',            70),
  -- ETA
  ('Vol Tratado',          'm3',   'ETA',            10),
  ('Vazão de tratamento',  'm3/h', 'ETA',            20),
  ('Turbidez',             'NTU',  'ETA',            30),
  ('Cloro Semi',           'ppm',  'ETA',            40),
  -- Represa
  ('Vazão de captação',    'm3/h', 'Represa',        10),
  ('Régua linimétrica',    'm',    'Represa',        20),
  ('Pluviometria',         'mm',   'Represa',        30)
on conflict (nome) do nothing;
