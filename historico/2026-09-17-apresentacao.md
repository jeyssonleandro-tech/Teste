# Registro — o botão Apresentar

Sessão de 17 de setembro de 2026.

---

## 1. O pedido

Um botão no topo do painel que gere a apresentação do mês, para levar à
reunião com a diretoria.

## 2. A escolha de formato

Três caminhos estavam na mesa. O escolhido foi **modo apresentação na
própria tela**, e não gerar um `.pptx`.

Gerar PowerPoint exigiria embutir uma biblioteca de ~1 MB no HTML — a rede
da empresa bloqueia CDN, então nada pode ser buscado na hora —, e os
slides sairiam mais pobres que a tela do painel, porque a biblioteca
desenha menos do que o SVG que já existe aqui.

Na tela, o custo é zero: o mesmo desenho, as mesmas fontes embutidas, a
mesma paleta. E **imprimir com a apresentação aberta gera o PDF**, uma
página por slide, sem nenhum código a mais.

## 3. O que tem em cada slide

**Capa** — logo, "Estações de Tratamento", o mês por extenso e a data de
emissão.

**Um slide por unidade** (a Produção fica de fora, como no painel):

- fechamento do mês de cada parâmetro, em número grande;
- **o mesmo número no mês anterior**, com seta e variação em %;
- verde ou vermelho pelos limites, com a regra do painel — o que compara
  contra o teto é o fechamento, ou os extremos dos dias quando o
  parâmetro é assim;
- o gráfico do mês, dia a dia, do primeiro parâmetro da unidade.

Navega por ‹ ›, seta do teclado, espaço ou PageUp/PageDown. Esc sai.

## 4. Duas decisões de implementação

**O modo é trocado por um instante em cada etapa.** O gráfico é do mês em
dias, e os números são do fechamento mensal — cada um pede um `modo`
diferente nos rótulos e nas regras de limite. O código salva o modo real,
troca, monta, e devolve. Está comentado onde acontece.

**O SVG nasce na largura em que vai ser visto.** Desenhar a 1180px e
deixar o CSS encolher para 340px no celular encolhe a fonte do eixo
junto, e ela some. A largura sai do `innerWidth`.

## 5. Validação

Playwright, monitor e celular:

- capa com mês, data de emissão e logo;
- um slide por unidade, sem a Produção;
- navegação por botão e por teclado, com ‹ travado no primeiro e › no
  último;
- a comparação com agosto aparece com seta e percentual;
- o índice c/ cerveja fechando em 1,43 contra teto de 1,40 acende em
  vermelho — e só ele;
- Esc fecha e o painel continua inteiro atrás;
- no celular: sem rolagem horizontal, slide não cortado, barra de
  navegação em **uma linha só** e fonte do eixo acima de 9px;
- nenhum recurso externo buscado.
