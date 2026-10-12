# Teste

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

## graphify (skill)

A skill [graphify](https://github.com/Graphify-Labs/graphify) foi instalada em
`.claude/skills/graphify/` (arquivo `SKILL.md` + `references/`), o mesmo
conteúdo que o instalador oficial (`graphify install --project`) gera para o
Claude Code.

Com a skill presente, `/graphify` fica disponível para transformar o projeto
(código, docs, PDFs, imagens, vídeos) em um grafo de conhecimento navegável
(`graphify-out/graph.html`, `graph.json`, `GRAPH_REPORT.md`), consultável via
`graphify query`, `graphify path` e `graphify explain`.

Para de fato rodar os comandos `/graphify`, é necessário instalar o CLI Python
no ambiente onde o Claude Code está rodando:

```bash
uv tool install graphifyy      # ou: pipx install graphifyy
```

Este repositório **não** inclui o hook `PreToolUse` nem o bloco "always-on" que
o instalador oficial também escreve em `.claude/settings.json` e `CLAUDE.md`
(eles pressupõem o binário `graphify` já disponível no PATH da máquina que
executa as sessões). Se quiser esse comportamento automático, rode
`graphify install --project` localmente após instalar o CLI. Licença MIT/
Apache-2.0 (ver `LICENSE` / `LICENSE-MIT` no repositório do graphify).
