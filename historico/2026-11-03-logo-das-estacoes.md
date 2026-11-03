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

Posição: ao lado do título, depois da logo Coca-Cola Andina — a marca
corporativa continua à esquerda. 36 px no monitor, 30 px no celular.
Login e apresentação não mudaram.

## Teste

`logo.mjs` (Playwright): painel e lançamento, monitor e celular, claro
e escuro. Confere a cor aplicada, o tamanho e a ausência de rolagem
horizontal.
