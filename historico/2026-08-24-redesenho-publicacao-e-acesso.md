# Registro — redesenho do painel, publicação e acesso fechado

Sessão de 24 de agosto de 2026. Continuação de
`2026-08-20-lancamento-diario-e-parametros.md`.

---

## 1. Pauta do dia

Três frentes: publicar no GitHub Pages, liberar o acesso por celular e
redesenhar o painel, que o supervisor considerou ruim de usar.

Mobile e redesenho acabaram sendo o mesmo trabalho — o painel não tinha
nenhuma regra de layout para tela pequena, então adaptar exigia redesenhar
de qualquer forma.

---

## 2. Duas descobertas que mudaram o plano

Ao inspecionar o repositório antes de responder:

| Descoberta | Consequência |
|---|---|
| Não existia branch `main` — o padrão era `claude/install-ecc-skill-7qjzir`, de outro projeto | Foi criado um `main` a partir do trabalho do dashboard, para o endereço do site não depender do branch de trabalho |
| O repositório era privado | GitHub Pages em repositório privado exige plano pago, e mesmo pago o **site** publicado é público |

A segunda transformou "publicar" numa decisão de segurança, não numa
tarefa técnica.

---

## 3. Decisão: o painel passa a exigir login

Opções postas: repositório público sem login, GitHub Pro, login no painel,
ou Cloudflare Pages.

**Escolhido: login no painel** (`06_acesso_autenticado.sql`).

O raciocínio: com a leitura fechada, o repositório pode ser público sem
risco — o que fica visível é código e SQL, não leituras. A chave `anon`
embutida no HTML deixa de ler as views e as tabelas e passa a servir só
para autenticar.

Detalhe que exigiu atenção: as views usam `security_invoker`, então valem
as policies das tabelas base. Revogar só o `select` das views não bastaria
— bastaria consultar as tabelas direto para contornar. Por isso as quatro
policies de leitura foram trocadas de `anon, authenticated` para
`authenticated`.

**Efeito colateral corrigido no mesmo commit:** o `lancamento.html` lia o
cadastro de unidades e parâmetros com a chave anônima (`comLogin = false`).
Passou a usar o token do usuário.

### Limitação conhecida e aceita por ora

Não existe separação entre quem lê e quem lança: qualquer usuário
autenticado pode gravar. Aceitável para a equipe própria; para fornecedor
com login, não. Registrado como item em aberto.

---

## 4. O redesenho

**Diagnóstico:** o problema não era estética, era hierarquia. Todas as
unidades empilhadas, ~30 cartões idênticos, nenhum mais importante que
outro. Para achar um número, varria-se a tela.

**Escolha do supervisor:** uma unidade por vez.

O que foi feito:

- **Abas de unidade** como navegação principal, roláveis na horizontal
- **Um gráfico grande** do parâmetro em destaque, com eixo de marcas
  redondas (`escalaBonita`) e rótulos de data espaçados conforme a largura
- **Lista compacta** dos demais parâmetros: nome, mini-tendência, valor e
  variação. Clicar troca o destaque — é assim que se navega
- **Mobile-first:** coluna única até 920px, duas colunas acima disso; alvos
  de toque de 36px ou mais; abas e filtros que não estouram a tela

**Decisão técnica:** o SVG é gerado na largura real do contêiner
(`clientWidth`) em vez de escalar por `viewBox`. Custa um redesenho no
`resize`, mas o texto do eixo sai nítido em vez de esticado.

### Verificação

Playwright com um Supabase falso (rotas interceptadas), em 390px e 1280px,
claro e escuro, semanal e diário, com tabela aberta. Checagens: nenhum erro
de console, tooltip alcançável no primeiro ponto da série densa (o bug da
sessão anterior), e nenhuma rolagem horizontal indevida.

---

## 5. A publicação, passo a passo real

O que o supervisor executou, com os tropeços que valem registro:

| Tropeço | O que era |
|---|---|
| Procurou os passos do GitHub dentro do Supabase | São dois sites diferentes; o guia não deixava isso explícito |
| "Não tem a opção Root" na tela do Pages | O seletor de pasta só aparece **depois** de escolher a ramificação |
| "Filial" no menu do GitHub em português | Tradução de *branch*; é o mesmo campo |

Resultado: repositório público, Pages ativo no `main`, site no ar em
`https://jeyssonleandro-tech.github.io/Teste/`.

O `06_acesso_autenticado.sql` foi rodado **antes** da publicação, então o
painel nunca esteve exposto.

---

## 6. O bloqueio da rede corporativa

No computador da empresa o site não abre:
`ERR_CONNECTION_TIMED_OUT` em `jeyssonleandro-tech.github.io`. Timeout sem
página de aviso — o firewall descarta em silêncio, típico de bloqueio por
categoria.

**O teste que resolveu o diagnóstico:** abrir
`https://hylrytsydjijrimwtpnv.supabase.co/rest/v1/` direto no navegador da
empresa. Voltou `{"message":"No API key found in request"}` — resposta do
banco. Ou seja:

- `supabase.co` → **passa**
- `github.io` → **barrado**

Note que `supabase.com` (painel de administração) e `supabase.co` (API do
banco) são domínios distintos para o filtro. Um passar não garante o outro.

### Solução imediata

Com o Supabase alcançável, o painel funciona **como arquivo local**: baixar
o `index.html`, abrir com dois cliques, e o navegador fala direto com o
banco. Testado e funcionando no computador da empresa.

Limitação: distribuição manual. Serve para o supervisor e uma equipe
pequena; não serve para mandar link a fornecedor.

### Encaminhamento

Foi redigido um pedido de liberação para a TI, com o argumento de LGPD
(nenhum dado pessoal, acesso autenticado, sem autocadastro, sem exclusão
pela aplicação).

**Decisão deliberada:** não trocar de provedor de hospedagem antes da
resposta da TI. Se o bloqueio do `github.io` foi intencional, migrar para
outro domínio só para escapar dele é passar por cima da decisão deles.

---

## 7. O que ficou pronto

| Arquivo | Conteúdo |
|---|---|
| `index.html` | Redesenhado: login, uma unidade por vez, gráfico grande, mobile-first |
| `lancamento.html` | Cadastro passa a ser lido com o token do usuário |
| `supabase/06_acesso_autenticado.sql` | Leitura só para autenticados, nas views e nas tabelas |
| `docs/publicacao-github-pages.md` | Passo a passo da publicação e do acesso por celular |
| branch `main` | Criado; é de onde o Pages publica |

**Atenção para as próximas sessões:** o site é servido pelo `main`.
Alteração que precisa aparecer no ar tem que chegar lá — não basta o branch
de trabalho.

---

## 8. Em aberto

| Item | Esperando |
|---|---|
| Liberação do `github.io` | Resposta da TI |
| Separar papéis leitor × lançador | Decisão de quando dar login a fornecedores |
| Índice de Água (L/L, ETA, calculado) | Parâmetros complementares e a fórmula |
| Sinalização de fora de faixa | Limites de conformidade por parâmetro |
| Branch padrão do repositório | Ainda aponta para `claude/install-ecc-skill-7qjzir`; trocar para `main` |
| Vínculo com a planta baixa | — |

### Nota sobre o plano gratuito do Supabase

O projeto é pausado após 7 dias sem nenhum acesso. Com lançamento diário
não acontece; é risco de parada prolongada. O conserto é *Restore project*
no painel, com os dados intactos.
