# Teste

## Dashboard de Estações de Tratamento

Painel de acompanhamento semanal das unidades (ETE Industrial, ETE Sanitária,
ETA e Represa), alimentado por dados no Supabase e publicado como HTML.

### Como está organizado

| Caminho | O que é |
|---|---|
| `index.html` | O painel — leitura com login, visão diária, semanal ou mensal |
| `lancamento.html` | Formulário de lançamento, com login por colaborador |
| `supabase/01_schema.sql` | Cria as tabelas e a view |
| `supabase/02_rls.sql` | Regras de acesso: leitura pública, escrita só autenticada |
| `supabase/03_cadastro_inicial.sql` | Cadastro inicial das unidades e dos parâmetros |
| `supabase/04_migracao_diaria.sql` | Migra para lançamento diário e cria o login |
| `supabase/05_parametros_v2.sql` | Amplia o cadastro e permite dupla agregação |
| `supabase/06_acesso_autenticado.sql` | Fecha a leitura: sem login, nada aparece |
| `supabase/07_limites.sql` | Limites de conformidade e sinalização de desvio |
| `supabase/08_ajustes_limites.sql` | Cloro Semi em ppm e alarme diário na ETE Industrial |
| `supabase/09_excluir_usuario.sql` | Permite excluir usuário sem perder as leituras |
| `supabase/10_visao_mensal.sql` | Visão mensal, por mês de calendário |
| `docs/guia-lancamento-supabase.md` | Guia de operação |
| `docs/publicacao-github-pages.md` | Como publicar o painel e liberar o celular |

### Modelo de dados

Três tabelas, em vez de uma coluna por indicador — assim cada tipo de unidade
usa só os parâmetros que fazem sentido para ela, e um indicador novo é apenas
uma linha nova em `parametros`:

- `unidades` — cadastro de cada estação/represa
- `parametros` — catálogo de indicadores, cada um com sua regra de agregação
- `leituras` — uma linha por unidade + parâmetro + **dia**

O registro é diário; a visão semanal é montada pelo banco na view
`vw_dashboard`, somando, mediando ou pegando o último valor conforme a
natureza de cada indicador.

### Acesso

| Quem | Como | Pode |
|---|---|---|
| Quem não tem login | — | Nada. O painel não mostra dado algum |
| Visitante (superior, fornecedor) | `index.html` + login | Ver o painel |
| Colaborador | `lancamento.html` + login | Lançar e corrigir medições |
| Supervisor | painel do Supabase | Tudo, inclusive apagar e criar logins |

O painel é publicado na internet, então a leitura passou a exigir
autenticação: a chave `anon` embutida no HTML só serve para fazer login.
Quem não tem usuário cadastrado não enxerga nada.

### Limites de conformidade

Cada parâmetro pode ter limite inferior e/ou superior. O painel marca o que
saiu da faixa e desenha as linhas de limite no gráfico.

A coluna `limite_base` resolve um caso que daria falso alarme: as águas por
produto têm teto **diário** (m³/d), mas são somadas na semana. Com
`limite_base = 'diario'`, a pergunta na visão semanal passa a ser "algum dia
do período estourou?" em vez de comparar a soma de 7 dias com o teto de 1.

### Próximos passos

1. Separar papéis leitor × lançador — hoje todo usuário autenticado pode
   gravar
2. Índice de Água na ETA — falta a fórmula e os parâmetros complementares
3. Vínculo com a planta baixa das unidades (campo `localizacao` reservado)

## ECC (Claude Code plugin)

Este repositório já vem com o plugin [ECC](https://github.com/affaan-m/ECC)
habilitado em `.claude/settings.json` (marketplace `ecc`, plugin `ecc@ecc`).

Ao abrir o projeto no Claude Code, o plugin é reconhecido automaticamente e o
Claude pede confiança na primeira vez. Para instalar manualmente (ou fora deste
projeto), rode dentro do Claude Code:

```text
/plugin marketplace add https://github.com/affaan-m/ECC
/plugin install ecc@ecc
```

Verificação: `/plugin` lista `ecc@ecc` como instalado, e `/help` passa a mostrar
os comandos do ECC.

O que vem junto: 284 skills, 68 agentes, 94 comandos e hooks gerenciados pelo
plugin. Licença MIT.
