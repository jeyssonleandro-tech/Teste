# Painel Financeiro

Dashboard de controle financeiro em arquivo único (`index.html`), sem dependências
externas — basta abrir no navegador.

Abre com dados **fictícios** de demonstração e aceita a sua planilha em CSV: o
arquivo é lido no próprio navegador, nada é enviado para fora.

## O que o painel mostra

| Bloco | Conteúdo |
|---|---|
| Indicadores | Caixa, receitas, despesas e margem líquida do período, com variação vs. mês anterior e sparkline |
| Fluxo de caixa | Receitas × despesas por mês, com crosshair e tooltip |
| Resultado mensal | Receitas − despesas por mês (barras para baixo nos meses de prejuízo) |
| Orçado × realizado | Centros de custo com desvio percentual sinalizado — exige coluna de orçamento |
| Despesas por categoria | Cinco maiores categorias, o restante agrupado em "Outras categorias" |
| Contas a pagar | Títulos não quitados, classificados em vencido / a vencer / programado — exige coluna de situação |

O filtro de período (tudo, últimos 6 meses, últimos 3 meses) recalcula os
indicadores e os dois gráficos de série mensal. Cartões sem dados suficientes se
escondem sozinhos e o painel avisa qual coluna faltou.

## Carregando sua planilha

No Google Sheets: **Arquivo → Fazer download → Valores separados por vírgula
(.csv)**. Depois clique em **Carregar planilha (CSV)** ou arraste o arquivo para a
página.

A primeira linha precisa ser o cabeçalho. Os nomes de coluna são reconhecidos por
sinônimos, ignorando maiúsculas e acentos:

| Campo | Nomes aceitos | Observação |
|---|---|---|
| Data | `data`, `vencimento`, `competência`, `mês` | obrigatório · `15/08/2026`, `2026-08-15` ou `ago/2026` |
| Valor | `valor`, `montante`, `total`, `r$` | obrigatório · aceita `R$ 1.234,56`, negativos e `(1.234,56)` |
| Tipo | `tipo`, `entrada/saída`, `d/c` | `receita`/`entrada`/`crédito` × `despesa`/`saída`/`débito`; sem a coluna, o sinal do valor decide |
| Categoria | `categoria`, `natureza`, `classificação`, `conta` | alimenta o gráfico de despesas |
| Centro de custo | `centro de custo`, `setor`, `departamento` | |
| Orçado | `orçado`, `orçamento`, `previsto` | somado uma vez por mês e centro de custo |
| Descrição | `descrição`, `fornecedor`, `histórico`, `item` | |
| Situação | `situação`, `status`, `pago` | títulos não quitados viram contas a pagar |

Uma linha cuja descrição contenha **saldo inicial** vira o caixa de abertura.

Separador (`;`, `,` ou tabulação) e formato numérico são detectados
automaticamente; a escala dos eixos se ajusta à ordem de grandeza dos valores.

## Detalhes de implementação

- Gráficos em SVG puro; barras horizontais em HTML/CSS; nenhuma biblioteca.
- Tema claro e escuro por tokens CSS, respondendo à preferência do sistema e ao
  atributo `data-theme`; os gráficos são redesenhados quando o tema muda.
- Paleta de séries validada para daltonismo e contraste (azul `#2a78d6` /
  laranja `#eb6834` no claro; `#3987e5` / `#d95926` no escuro).
- Legenda sempre visível e rótulos diretos no fim das linhas — que se afastam
  quando as duas pontas se encostam —, para que a identidade das séries nunca
  dependa só da cor. A série mensal também está disponível em tabela.
- Os dados de exemplo ficam em `dadosExemplo()`, no topo do `<script>`.
