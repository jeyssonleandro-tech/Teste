# Registro — o formulário de lançamento ganha o desenho do painel

Sessão de 8 de setembro de 2026. Continuação de
`2026-09-04-indice-de-agua.md`.

---

## 1. O pedido

Aplicar no `lancamento.html` as mesmas decisões de design feitas no painel,
e colocar a logo também nesta página.

O ponto de partida eram duas telas que não pareciam o mesmo produto: o
painel com paleta quente, tipografia embutida e a marca como filete; o
formulário com um azul genérico de sistema, fonte do sistema operacional e
nenhuma marca.

---

## 2. O que veio do painel, sem mudança

- **Paleta idêntica** — os mesmos tokens, claro e escuro, com o botão de
  tema no cabeçalho.
- **Tipografia embutida** — Barlow, Barlow Semi Condensed e IBM Plex Mono
  como data URI. Pelo mesmo motivo de sempre: a rede da empresa bloqueia
  domínios, e uma fonte buscada no Google Fonts cairia para a do sistema
  justamente no computador onde o arquivo é usado.
- **Logo + filete vermelho** — a marca entra como faixa de 4px, não como
  bloco saturado. Também na tela de entrada, acima do filete.
- **Abas de unidade centralizadas** — as mesmas do painel, no lugar do
  `<select>`. Trocar de unidade virou um toque, não dois.
- **Cabeçalho fixo** e a mesma quebra de linha no celular: abaixo de 560px
  o título desce para a linha de baixo em vez de sumir em reticências.

---

## 3. O que é próprio de um formulário

Copiar o painel inteiro seria errado: um lê, o outro escreve.

- **Contador de preenchidos** — *"7 de 12 preenchidos"* ao lado do nome da
  unidade, atualizado a cada tecla. Numa lista de doze medições, saber o
  que falta é metade do trabalho.
- **Botão que acompanha a rolagem** — no celular, com doze campos, o botão
  de salvar estaria sempre fora da tela na hora em que faz falta.
- **Turno como interruptor de duas posições**, no lugar do `<select>`: são
  duas opções, e um menu suspenso para duas opções é um clique a mais sem
  nenhuma vantagem.
- **Contorno de campo mais forte que a divisória do painel.** A WCAG 1.4.11
  pede 3:1 para o contorno de um elemento preenchível; o `--rule` do painel
  é divisória de leitura e some contra o fundo. Entrou um token próprio,
  `--campo` (#928988 no claro, #6B6463 no escuro), medido em 3,03:1 e
  3,25:1 contra o fundo.

---

## 4. Um defeito corrigido de passagem

No arquivo anterior, `abrirLancamento()` chamava `ajustarTurno()` **antes**
de `carregarCadastro()`. Na primeira entrada a lista de unidades ainda
estava vazia, então a função decidia se mostrava o campo de turno olhando
para uma unidade inexistente — e o campo ficava escondido até a pessoa
trocar de unidade e voltar.

A ordem agora é cadastro → unidade → turno → parâmetros.

---

## 5. Validação

Suíte Playwright contra um Supabase falso, monitor e celular:

- logo visível nas duas telas e faixa vermelha presente;
- abas montadas na ordem certa, primeira unidade ativa;
- turno escondido na ETA e presente na ETE Industrial, com duas posições;
- valor já lançado preenchido no campo, com a marca de substituição, e a
  observação existente recuperada;
- contador acompanhando a digitação;
- a consulta de parâmetros filtrando `calculado=is.false`;
- a gravação levando o turno escolhido e a vírgula virando ponto;
- valor inválido barrado antes de chegar ao banco;
- nenhum recurso externo buscado, nenhuma rolagem horizontal no celular,
  título não cortado e botão de salvar visível durante a rolagem.

Todos os pares de cor novos medidos: mínimo 4,5:1 para texto e 3:1 para
marcas gráficas, nos dois temas.
