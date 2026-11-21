# Comparar meses e modo TV

Data: 21/11/2026 (America/Sao_Paulo)

## Pedido

1. Comparar mês a mês: o filtro só deixava olhar um mês por vez.
2. Um modo em que os gráficos passam sozinhos — a ETE Industrial, por
   exemplo, com 30 s entre um gráfico e outro — para ficar na tela dos
   laboratórios.

## Comparação (`Comparar`, quarto botão do período)

- De 2 a 4 meses, escolhidos num menu de marcar (que não fecha a cada
  clique). Abre com o mês em tela contra o anterior.
- **O número de cada mês** vem de `vw_dashboard_mensal`, a mesma visão do
  modo Mensal, e por isso respeita a regra de cada parâmetro (soma, média,
  razão). Nada é recalculado no navegador.
- **O gráfico** vem de `vw_leituras_diarias`, uma consulta por mês, com os
  meses sobrepostos pelo dia do mês. `graficoGrande()` ganhou `opcoes.eixo`
  (eixo por dia do mês) e `opcoes.altura`; o comportamento sem opções é o
  de antes.
- Julgamento: o número do mês é julgado como mês e o gráfico como dia. O
  painel já fazia essa troca de `modo` na apresentação; ficou em
  `emModo(modo, fn)`.
- Cores: azul (mais recente), cinza, laranja e roxo, todas acima de 4,5:1
  nos dois temas e nenhuma é o vermelho de desvio ou o verde de conforme.
- Mês em andamento: marcado, e em parâmetros de total o painel avisa que
  não é comparável com um mês completo. Uma comparação "até o mesmo dia"
  não foi feita — ficou como possível evolução.
- Defeito encontrado e corrigido: o menu fechava a cada clique, porque o
  botão era redesenhado antes de o clique chegar ao "fechar ao clicar
  fora". O fechamento passou a usar `composedPath()`.

## Modo TV

- Botão **Modo TV** no topo. Diálogo com unidade (ou todas), tempo por
  gráfico (10 s a 1 min), tela cheia e o endereço direto
  (`?tv=<unidade|todas>&seg=<s>`), que abre já no modo TV.
- Reaproveita a tela normal: só avança `unidadeAtiva`/`paramAtivo` e chama
  `desenhar()`. Não há segunda implementação para manter.
- Some o que é controle; a tela cresce por zoom (1× a 2,4×, conforme a
  tela) e o gráfico ocupa a altura que sobra. Testado em 1280×720,
  1366×768 e 1920×1080 sem rolagem, inclusive a ETE Industrial com os
  tanques ao lado.
- Se mantém: refaz a consulta a cada 5 min, acompanha a virada do mês,
  pede `wakeLock`, e sem rede mostra o último dado com a hora dele.
- Sair: Esc, botão, sair da conta ou sair da tela cheia. Setas e espaço.
- `carregarNiveis()` foi extraída de `abrirPainel()` (só troca tanques e
  níveis depois das duas consultas darem certo).

## Teste (Playwright, banco simulado com set/out/nov)

`cmp.mjs` (nos dois temas, monitor e celular), `tv.mjs` (relógio
simulado: tempos, pausa, setas, atualização de 5 min, queda de rede,
endereço, unidade desconhecida, sair da conta), `regressao.mjs` (Diário,
Semanal, Mensal, tabela, Apresentar), mais `virada.mjs`, `logo.mjs` e
`larguras.mjs` das mudanças anteriores. Tudo passando.
