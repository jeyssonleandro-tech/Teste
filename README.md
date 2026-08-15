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
