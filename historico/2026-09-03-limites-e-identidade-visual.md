# Registro — limites de conformidade e identidade visual

Sessão de 3 de setembro de 2026. Continuação de
`2026-08-24-redesenho-publicacao-e-acesso.md`.

---

## 1. Os limites de conformidade

O supervisor trouxe a tabela de limites — superior e inferior — dos 24
parâmetros. Treze têm limite; o resto ficou sem.

### O problema que a lista revelou

`Água Cervejaria`, `Água refrigerante` e `Água XS` têm limite em **m³/dia**
(1.600, 4.600 e 1.600), mas são agregadas por **soma** na visão semanal. O
painel exibe o total de sete dias — perto de 11.200 m³ para a Cervejaria.
Comparar isso com 1.600 acusaria desvio toda semana, sempre.

**Solução:** a coluna `parametros.limite_base` diz a que valor o limite se
aplica.

| Valor | Significado |
|---|---|
| `periodo` | o limite vale para o número que o painel exibe |
| `diario` | o limite vale para cada dia; na semana, a pergunta vira "algum dia estourou?" |

A view passou a entregar `valor_min_dia` e `valor_max_dia` — os extremos
do período — que são o que responde essa pergunta.

### Decisões sobre a lista

| Item | Decisão |
|---|---|
| Cloro Semi: `ppm` na lista, `mg/L` no cadastro | Passou a `ppm`. Para água o número é o mesmo; o rótulo tem que bater com o que a equipe usa |
| Água Cervejaria e Água XS com teto idêntico de 1.600 | Confirmado pelo supervisor — não era cópia de linha. Registrado em comentário no SQL |
| ETE Industrial comparada pela média da semana | Passou a alarmar pelo **pior dia**. Uma semana com média dentro da faixa escondia o dia que saiu |
| Limites inferiores de 0 (Acidez, Cloro, DQO Eflu, N, P) | Mantidos. Nunca disparam em grandeza não-negativa, mas documentam a intenção e fazem o gráfico mostrar a faixa permitida inteira |

### A consequência que a mudança da ETE Industrial trouxe

A regra original era "limite diário não desenha linha de referência",
pensada para as águas. Mas pH e DQO agregam por **média**: ali o número
desenhado está na mesma escala do limite, e a linha continua valendo.

A condição passou a olhar a **agregação**, não a base do limite:

```js
const limiteDesenhavel = p =>
  !(modo === "semanal" && p.limBase === "diario" && p.agreg === "soma");
```

O teste pegou isso porque a checagem foi escrita antes do ajuste no código.

---

## 2. A identidade visual

O supervisor trouxe a paleta institucional e a logo.

### Duas cores não serviam como estavam

Rodei os contrastes antes de aplicar. O mínimo é 4,5:1 para texto e 3:1
para símbolos.

| Problema | Número | Solução |
|---|---|---|
| Verde `#01BF06` sobre o fundo claro `#E7E6E6` | **1,99:1** — ilegível | `#017304` no tema claro: mesma matiz de 122°, mesma saturação, só mais escuro → 4,88:1. O verde oficial fica no tema escuro, onde dá 7,4:1 |
| Linha do gráfico `#C62626` vs. fora de faixa `#C00000` | distância 54 — o mesmo vermelho na tela | A linha passou ao cinza secundário `#595959`, também oficial. O vermelho ficou reservado para o desvio |

O segundo é o mais importante: com o gráfico inteiro vermelho, o alerta
deixava de alertar. Faz sentido na planilha, onde o vermelho da linha é só
"o dado"; no painel o vermelho passou a ter significado, e não pode ter
dois.

### Onde cada cor foi parar

| Onde | Claro | Escuro |
|---|---|---|
| Faixa do topo | `#C00000`, texto branco | igual — a faixa não muda com o tema |
| Fundo da página | `#E7E6E6` | `#141413` |
| Títulos e números | `#0A0A0A` | `#FFFFFF` |
| Série do gráfico | `#595959` | `#A8A8A8` |
| Dentro do limite | `#017304` | `#01BF06` |
| Fora do limite | `#C00000` | `#F05353` |

A lista oficial não cobre fundo escuro; esses tons mantêm as matizes,
clareados até passarem no contraste.

### Três estados, não dois

O supervisor pediu verde para dentro e vermelho para fora. Foi implementado
com um terceiro: **sem limite cadastrado fica cinza.**

Pintar de verde um parâmetro que ninguém verificou afirmaria conformidade
que o dado não sustenta. Ficam neutros: Volume Tratado, Turbidez, Vazão de
captação, Pluviometria, Vazão de Entrada, DQO Eflu Bruto e Volume de
produção.

Cada estado leva também um símbolo — ✓, ▲, ▼. Cerca de 8% dos homens não
distingue vermelho de verde; cor sozinha não comunicaria a eles.

### A logo

PNG 1875×318 com fundo transparente, 14,6 KB. Embutida como data URI
(~19,5 KB de texto) em vez de referenciada: é o que permite copiar o
`index.html` entre pastas sem a imagem sumir — e é assim que o painel roda
no computador da empresa, onde o `github.io` está bloqueado.

Fica sobre uma placa branca dentro da faixa: uma logo colorida
desapareceria sobre o vermelho da própria faixa.

**O supervisor aprovou colocá-la também na versão publicada na internet.**
A recomendação registrada foi buscar um aval de quem cuida de comunicação
antes — marca de empresa em página aberta não é decisão técnica.

---

## 3. Percalços do dia

| Erro | Causa | Solução |
|---|---|---|
| A placa branca da logo aparecia vazia | `display: block` no CSS vence o atributo `hidden` do navegador | Regra explícita `img.logo[hidden] { display: none; }` |
| Linha selecionada parecia alerta | O realce usava um vermelho translúcido | Passou a cinza neutro |
| Chip selecionado ilegível no tema escuro | Texto branco sobre `#A8A8A8` = 2,2:1 | Inverteu: chip claro com texto escuro, 15,89:1 |
| Teste acusou falta das linhas de limite no pH | O mock tratava "limite diário" e "agregação por soma" como a mesma coisa; no banco são independentes | Agregação virou campo próprio da fixture |

---

## 4. O que ficou pronto

| Arquivo | Conteúdo |
|---|---|
| `supabase/07_limites.sql` | Colunas de limite, `limite_base`, os 13 limites, views com os extremos do período |
| `supabase/08_ajustes_limites.sql` | Cloro Semi em ppm, ETE Industrial com alarme diário |
| `index.html` | Paleta institucional, faixa com a logo, três estados, pontos fora da faixa em vermelho no gráfico |

A página de aprovação da identidade foi publicada como artefato privado
para o supervisor revisar antes de validar.

---

## 6. O login que não entrava

Depois de tudo pronto, o supervisor não conseguia mais entrar. Foram
levantadas quatro causas prováveis — provedor de e-mail desligado, usuário
não confirmado, senha errada, sessão travada no navegador.

**Nenhuma era.** O diagnóstico veio de uma consulta em `auth.users`:

```sql
select email,
       case when encrypted_password is null then 'SEM SENHA' else 'tem senha' end as senha,
       case when email_confirmed_at is null then 'NÃO CONFIRMADO' else 'confirmado' end as confirmacao,
       last_sign_in_at
  from auth.users where deleted_at is null;
```

Duas coisas apareceram de uma vez:

1. Os dois usuários estavam íntegros — com senha, confirmados, ativos.
2. Havia um **login bem-sucedido de hoje**, doze minutos antes. Isso
   provava que o provedor estava ligado e derrubava a suspeita principal.

Levantou-se então a hipótese do e-mail cadastrado com ponto
(`jeysson.leandro@gmail.com`) contra o digitado sem ponto — o Gmail trata
os dois como a mesma caixa, o Supabase não. **Também não era.**

A causa apareceu com uma pergunta do supervisor: *"fiz a configuração pelo
PC do trabalho e estou mexendo pelo celular, será que tem relação?"*

Tinha. O mesmo arquivo entrava no PC e não no celular, o que descartava as
credenciais e apontava para o ambiente.

### A causa real: `localStorage` recusado em `file://`

O painel estava sendo aberto no celular **como arquivo**, não pelo endereço
da internet. O iOS trata páginas `file://` como origem sem identidade e
recusa o acesso ao `localStorage` — que é onde a sessão é guardada.

A sequência era esta:

1. O Supabase aceitava a senha e devolvia o token
2. A linha seguinte tentava gravar a sessão
3. O navegador lançava `SecurityError`
4. O `catch` do formulário tratava isso como falha de credencial

A pessoa entrava e era expulsa no mesmo instante, com a mensagem errada na
tela. No PC não aparecia porque o Chrome de computador permite gravar em
`file://`.

**A correção:** lembrar a sessão virou conveniência opcional. As três
operações passaram por `guardarSessao` / `lerSessao` / `esquecerSessao`,
que engolem a recusa. Sem memória o login funciona igual — só não sobrevive
ao recarregar, e o painel diz isso em vez de fingir erro de senha. Vale
também para aba privada e navegador com cookies bloqueados.

**Princípio que ficou:** uma conveniência não pode derrubar a função
principal. Guardar sessão é conforto; entrar é o produto.

**Para o dia a dia:** no celular, abrir pelo endereço da internet, onde a
sessão fica guardada. O arquivo continua sendo a saída no computador da
empresa, onde o `github.io` está bloqueado.

### Correções que o episódio gerou

| Problema | Correção |
|---|---|
| Qualquer 400 do Supabase virava "E-mail ou senha incorretos", mandando procurar senha quando a causa era outra | As telas passaram a nomear cada caso: não confirmado, provedor desligado, usuário suspenso, excesso de tentativas, e-mail malformado |
| `leituras.registrado_por` referenciava `auth.users` sem `ON DELETE`, então excluir um usuário que já lançou dados era impossível — o Supabase mostrava só "Database error deleting user" | `09_excluir_usuario.sql`: passou a `ON DELETE SET NULL`. A leitura fica, o rastro some |
| Recusa do `localStorage` derrubava o login inteiro | Armazenamento isolado em funções que engolem a falha |

A recuperação de senha por e-mail não funcionou: o serviço embutido do
plano gratuito tem limite baixo e a mensagem não chegou. O caminho que
funciona é definir a senha direto no banco:

```sql
update auth.users
   set encrypted_password = extensions.crypt('nova senha', extensions.gen_salt('bf')),
       email_confirmed_at = coalesce(email_confirmed_at, now())
 where email = '...';
```

Para a equipe usar isso de verdade, vale configurar um SMTP próprio em
Settings → Authentication → SMTP.

---

## 7. Ajustes finais no frontend

Feitos depois de o supervisor olhar o painel pronto no computador.

| Pedido | O que foi feito |
|---|---|
| Título "Dashboard Estações de tratamento" | Na página e na aba do navegador |
| Faixa com mais margem | Altura e recuos laterais aumentados |
| Logo sem fundo branco, compondo a faixa | A placa branca saiu: a logo fica sobre o fundo da página, à esquerda, e o bloco vermelho ao lado, até a borda da coluna |
| Abas de unidade centralizadas | `justify-content: safe center` |
| Botão Mensal | `10_visao_mensal.sql` + terceiro modo no painel |

### A proporção da logo obrigou a empilhar no celular

A logo é 1875×318 — proporção de quase 6:1. Lado a lado com o título numa
tela de 390px, ela consumia a largura toda e o título ficava truncado em
"Das...". Abaixo de 820px as duas partes empilham: logo em cima, faixa
vermelha ocupando a largura toda embaixo, título em duas linhas. Entre 820
e 1080px a logo encolhe pelo mesmo motivo — cada pixel de altura custa seis
de largura ao bloco vermelho.

O `safe` do `justify-content` resolve um problema clássico: centralizar um
contêiner rolável esconderia os primeiros itens fora da área alcançável
quando as unidades não coubessem na tela.

### O mensal exigiu rever a regra do limite diário

A condição olhava `modo === "semanal"`. No mensal, sem ajuste, o painel
compararia o teto de 1.600 m³/dia com a soma de 30 dias — desvio garantido
toda vez. Passou a valer em qualquer visão agregada.

Os rótulos no modo mensal viraram `MM/AAAA`. A coluna do banco guarda o dia
1 do mês; exibir `01/10/2026` induziria a ler como uma data específica.

### Sobre os dados retroativos

O formulário aceita data passada sem restrição. Duas recomendações
registradas: lançar **dia a dia**, porque semanal e mensal são calculados a
partir dos dias — um valor mensal fechado num único dia estraga a média e
os extremos; e conferir a visão mensal depois de subir, porque é onde erro
de data salta à vista.

---

## 8. Redesenho: sete críticas respondidas

O supervisor pediu um olhar crítico sobre o visual, com vista a apresentar
o painel ao seu superior, e deu liberdade sobre as cores — "dei uma base,
não uma obrigação".

| # | O que estava datado | O que passou a ser |
|---|---|---|
| 1 | Oito pílulas idênticas misturando três tipos de controle | Interruptor de três posições + menu suspenso para a janela de tempo + botão discreto para a tabela |
| 2 | Tudo cartão com a mesma borda, raio e fundo | O gráfico respira sobre o fundo; só a tabela mantém moldura |
| 3 | Tipografia do navegador, um tamanho para tudo | Barlow em duas larguras + IBM Plex Mono para unidades e eixos |
| 4 | Bloco vermelho atravessando o topo | Filete sob o cabeçalho |
| 5 | Unidades como pílulas soltas | Abas com sublinhado + nome da unidade encabeçando o conteúdo |
| 6 | Divisória entre todas as linhas da lista | Espaço; mini-tendências com a referência do limite |
| 7 | Nada dizia por onde começar | Resumo: "7 parâmetros · 3 fora de faixa · 12 semanas até …" |

### Decisões que valem registro

**Neutros com viés quente.** Um cinza morto ao lado de um vermelho
saturado denuncia que as duas coisas não foram escolhidas juntas. Os
neutros passaram a puxar para o vermelho da marca. Todos os pares foram
medidos: mínimo 4,5:1 para texto, 3:1 para marcas gráficas.

**Fontes embutidas no arquivo.** Decisão de engenharia, não de estética. O
painel roda como arquivo solto no computador da empresa, cuja rede bloqueia
domínios — o `github.io` já está barrado. Se as fontes viessem do Google
Fonts, cairiam para a fonte do sistema justamente na máquina onde o painel
seria apresentado, e todo o desenho tipográfico desapareceria. Subconjunto
latino, 117 KB de woff2, arquivo final em 228 KB. Pesado para uma página
web, irrelevante para um arquivo aberto do disco.

O teste pegou isso: a suíte acusou `ERR_CONNECTION_RESET` ao buscar o
Google Fonts, o que revelou a dependência antes de ela chegar ao usuário.

**Margem condicional no gráfico.** A margem direita existe para os rótulos
de limite. Em parâmetro sem limite ela virava espaço morto e encolhia o
desenho sem motivo — passou a depender da existência dos limites.

**O título ganha a própria linha abaixo de 560px.** Logo, título e ações
não cabem juntos numa tela estreita, e quem cedia era o título, truncado em
"Dashboa…".

---

## 9. Em aberto

| Item | Esperando |
|---|---|
| Liberação do `github.io` | Resposta da TI |
| Aval de comunicação sobre a logo na página pública | Consulta interna |
| Separar papéis leitor × lançador | Antes de dar login a fornecedores |
| Índice de Água (L/L, ETA, calculado) | Parâmetros complementares e a fórmula |
| Branch padrão do repositório | Ainda aponta para `claude/install-ecc-skill-7qjzir`; trocar para `main` |
| Vínculo com a planta baixa | — |
| SMTP próprio para recuperação de senha | Servidor de e-mail da empresa |
