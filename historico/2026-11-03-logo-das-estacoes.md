# Logo das estações no cabeçalho

Data: 03/11/2026 (America/Sao_Paulo)

## Pedido

Inserir a logo das estações no cabeçalho do painel e do lançamento:
azul no tema claro, branca no tema escuro.

## Como foi feito

As duas versões enviadas (azul e branca) são o mesmo desenho em cores
diferentes. Em vez de embutir dois arquivos e trocar um pelo outro, o
desenho entra **uma vez**, como máscara (`mask` do CSS), e é pintado
com a variável de tema `--marca-ete`:

- claro: `#013C5C` (o azul medido na arte enviada)
- escuro: `#FFFFFF`

A troca acompanha o botão "Tema" sozinha, sem JavaScript.

A arte veio em JPEG com fundo cinza-claro, sem transparência. A máscara
foi recortada da versão azul (fundo vira transparente, o reflexo da
gota é preservado). Fica em `docs/logo-estacoes-mascara.png` (221×224 px)
e embutida em base64 nos dois HTML.

Posição (ajustada a pedido no mesmo dia): uma marca em cada lado do
cabeçalho — Coca-Cola Andina à esquerda, logo das estações à direita,
junto dos botões Apresentar/Tema/Sair. No celular as duas logos ficam na
primeira linha, em lados opostos; no painel os botões descem para a
linha de baixo, alinhados à direita. 36 px no monitor, 28 px no celular.
Login e apresentação não mudaram.

De passagem: entre 561 e ~640 px de largura a linha de controles
(Diário/Semanal/Mensal, mês, turno, tabela) não quebrava e gerava
rolagem horizontal de 137 px. `.controles` ganhou `max-width: 100%`.

## Teste

`logo.mjs` (Playwright): painel e lançamento, monitor e celular, claro
e escuro, mais 320, 480, 600 e 820 px. Confere a cor aplicada, o
tamanho e a ausência de rolagem horizontal.
