# Painel Financeiro 2026

Dashboard de controle financeiro em arquivo único (`index.html`), sem dependências
externas — basta abrir no navegador.

> Todos os números são **fictícios**, criados apenas para demonstrar o layout.

## O que o painel mostra

| Bloco | Conteúdo |
|---|---|
| Indicadores | Caixa disponível, receitas, despesas e margem líquida do período, com variação vs. mês anterior e sparkline |
| Fluxo de caixa | Receitas × despesas por mês, com crosshair e tooltip |
| Resultado mensal | Receitas − despesas por mês, com margem no tooltip |
| Orçado × realizado | Seis centros de custo, com desvio percentual sinalizado |
| Despesas por natureza | Cinco naturezas de gasto, ordenadas por valor |
| Contas a pagar | Títulos em aberto com situação (vencido / a vencer / programado) |

O filtro de período (ano até agosto, últimos 6 meses, últimos 3 meses) recalcula
os indicadores e os dois gráficos de série mensal.

## Onde trocar os dados

Todos os valores ficam no topo do `<script>`, em `index.html`:

- `RECEITAS`, `DESPESAS`, `CAIXA_INICIAL` — série mensal, em R$ mil
- `CENTROS` — orçado e realizado por centro de custo, em R$ mil
- `NATUREZA` — despesas por natureza, em R$ mil
- `CONTAS` — títulos a pagar, em reais
- `HOJE` — data de referência que classifica os títulos como vencidos ou a vencer

## Detalhes de implementação

- Gráficos desenhados em SVG puro; barras horizontais em HTML/CSS.
- Tema claro e escuro pelos tokens CSS, respondendo à preferência do sistema e ao
  atributo `data-theme`; os gráficos são redesenhados quando o tema muda.
- Paleta de séries validada para daltonismo e contraste (azul `#2a78d6` /
  laranja `#eb6834` no claro; `#3987e5` / `#d95926` no escuro).
- Legenda sempre visível e rótulos diretos no fim das linhas, para que a
  identidade das séries nunca dependa só da cor. A série mensal também está
  disponível em tabela, ao pé da página.
