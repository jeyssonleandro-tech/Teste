# Teste

## Agente de conteúdo do LinkedIn

Automação para gerar, revisar, agendar e publicar posts no LinkedIn via API,
com aprovação manual antes de qualquer publicação. Veja o guia completo de
configuração em [`docs/SETUP.md`](docs/SETUP.md) — inclui como criar o app no
LinkedIn Developer Portal, autorizar via OAuth e cadastrar os GitHub Secrets.

Estrutura:

- `src/lib/` — clientes de OAuth e da API do LinkedIn, e a fila de posts.
- `scripts/` — CLIs (`npm run auth:*`, `npm run queue:*`, `npm run metrics:collect`).
- `content/queue/` — fila de posts (rascunho → revisão → aprovado → publicado). Ver [`content/README.md`](content/README.md).
- `.github/workflows/` — publicação agendada (hora em hora) e coleta diária de métricas.

**Limitação importante**: a API pública do LinkedIn não expõe métricas de
alcance/impressões para posts de perfil pessoal — apenas curtidas/comentários
quando disponíveis. Detalhes em `docs/SETUP.md`.

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
