# Teste

## Dashboard de Estações de Tratamento

Painel de acompanhamento semanal das unidades (ETE Industrial, ETE Sanitária,
ETA e Represa), alimentado por dados no Supabase e publicado como HTML.

### Como está organizado

| Caminho | O que é |
|---|---|
| `supabase/01_schema.sql` | Cria as tabelas `unidades`, `parametros`, `leituras_semanais`, `ocorrencias` e a view `vw_dashboard` |
| `supabase/02_rls.sql` | Regras de acesso: leitura pública, escrita só autenticada |
| `supabase/03_cadastro_inicial.sql` | Cadastro inicial das unidades e dos parâmetros (ajustar antes de rodar) |
| `docs/guia-lancamento-supabase.md` | Guia de operação: como lançar os dados toda semana |

### Modelo de dados

Três tabelas, em vez de uma coluna por indicador — assim cada tipo de unidade
usa só os parâmetros que fazem sentido para ela, e um indicador novo é apenas
uma linha nova em `parametros`:

- `unidades` — cadastro de cada estação/represa
- `parametros` — catálogo de indicadores (DQO, pH, Turbidez, Vazão...)
- `leituras_semanais` — uma linha por unidade + parâmetro + semana

### Próximos passos

1. Rodar os scripts de `supabase/` no SQL Editor (ver guia)
2. Cadastrar unidades e parâmetros
3. Construir o `index.html` do dashboard
4. Publicar via GitHub Pages

Em standby para o futuro: formulário HTML de lançamento, para substituir o
Table Editor na rotina semanal.

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
