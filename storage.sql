-- ============================================================================
-- SEED — estoque inicial de matéria-prima
-- Rodar DEPOIS do schema.sql. Valores copiados do protótipo (orcamento-cortinas-poc.html)
-- só pra não começar com o app vazio — ajuste os saldos reais antes de usar em produção.
-- ============================================================================

insert into estoque_mp (id, nome, unidade, categoria, saldo, minimo) values
  ('linho_flame',          'Linho Flame',              'm',  'Tecido',    120, 40),
  ('forro_microfibra',     'Forro Microfibra',         'm',  'Tecido',     70, 25),
  ('semiblackout',         'Semi-blackout',             'm',  'Tecido',     35, 20),
  ('blackout',             'Blackout 100%',              'm',  'Tecido',     18, 20),
  ('trilho_simples',       'Trilho simples',            'm',  'Estrutura',  55, 20),
  ('trilho_duplo',         'Trilho duplo',               'm',  'Estrutura',  30, 15),
  ('trilho_duplo_largo',   'Trilho duplo largo',         'm',  'Estrutura',  12, 15),
  ('trilho_triplo',        'Trilho triplo',              'm',  'Estrutura',  10, 10),
  ('tubo',                 'Tubo deslizante',            'm',  'Estrutura',  45, 20),
  ('varao_grosso',         'Varão grosso',                'm',  'Estrutura',  38, 15),
  ('varao_medio',          'Varão médio',                 'm',  'Estrutura',  38, 15),
  ('presilha',             'Presilhas (todas)',          'un', 'Acessório', 260, 100),
  ('deslizante',           'Deslizantes',                 'un', 'Acessório', 900, 300),
  ('terminal',             'Terminais',                    'un', 'Acessório',  80, 40),
  ('tampa',                'Tampas (tubo)',                'un', 'Acessório',  40, 20),
  ('suporte',              'Suportes',                     'un', 'Acessório',  26, 20),
  ('bucha',                'Buchas',                        'un', 'Acessório', 300, 120),
  ('parafuso',             'Parafusos',                     'un', 'Acessório', 300, 120),
  ('ilhos',                'Ilhoses',                        'un', 'Acessório', 220, 100),
  ('argola',                'Argolas',                        'un', 'Acessório', 190, 100),
  ('persiana_rolo_screen', 'Persiana Rolô Screen',        'm²', 'Persiana',   40, 15)
on conflict (id) do nothing;
