# Skills do ECC (vendored)

As 284 skills deste diretório vêm do projeto
[ECC](https://github.com/affaan-m/ECC), copiadas para dentro do repositório
para que carreguem em qualquer sessão do Claude Code — inclusive nas sessões
na nuvem, onde o sistema de plugins (`/plugin`) não está disponível.

- Origem: `affaan-m/ECC`
- Versão: 2.2.0
- Commit: `f1923017275a69516822ad551a8dfed34a772723`
- Licença: MIT (ver `LICENSE` neste diretório)

## Atualizar

Não há atualização automática — esta é uma cópia congelada. Para sincronizar
com a versão mais recente:

```sh
git clone --depth 1 https://github.com/affaan-m/ECC.git /tmp/ecc
rm -rf .claude/skills/*/
cp -R /tmp/ecc/skills/. .claude/skills/
```

Depois atualize o commit e a versão anotados acima.

## Instalação como plugin

No Claude Code local, o caminho oficial continua sendo o plugin — já
configurado em `.claude/settings.json`, ou manualmente:

```text
/plugin marketplace add https://github.com/affaan-m/ECC
/plugin install ecc@ecc
```

Se você usar o plugin **e** esta cópia ao mesmo tempo, as skills aparecem
duplicadas. Nesse caso, apague este diretório e fique só com o plugin.
