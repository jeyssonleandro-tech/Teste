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

## 5. Em aberto

| Item | Esperando |
|---|---|
| Liberação do `github.io` | Resposta da TI |
| Aval de comunicação sobre a logo na página pública | Consulta interna |
| Separar papéis leitor × lançador | Antes de dar login a fornecedores |
| Índice de Água (L/L, ETA, calculado) | Parâmetros complementares e a fórmula |
| Branch padrão do repositório | Ainda aponta para `claude/install-ecc-skill-7qjzir`; trocar para `main` |
| Vínculo com a planta baixa | — |
