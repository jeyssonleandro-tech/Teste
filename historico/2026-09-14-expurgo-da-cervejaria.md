# Registro — a água da cervejaria sai do índice geral

Sessão de 14 de setembro de 2026. Continuação de
`2026-09-10-tanques.md`.

---

## 1. O pedido

A água que vai para a cervejaria já tem índice próprio. Mantê-la também
no índice geral cobrava a mesma água duas vezes e escondia o desempenho
do resto da fábrica atrás do consumo de uma linha só.

O desconto é **no FIT 100, antes da soma**:

```
Índice de Água = ((Volume FIT 100 − Água Cervejaria)
                  + Caminhão Pipa + Volume Andina 1) × 1000
                 ÷ (Volume de produção × 5,678)
```

Denominador inalterado. Índice de Água Cervejaria inalterado.

---

## 2. Onde o desconto entra importa

Subtrair antes ou depois da soma dá o mesmo número — a diferença está em
**qual parcela carrega o desconto**, e isso aparece na `vw_indice_agua`,
que devolve `agua_m3` ao lado do valor. Descontando no FIT 100, o que a
view mostra é a água tratada que de fato sobrou para a fábrica. Foi o que
se pediu e é o que se audita.

---

## 3. Dois cuidados registrados porque mudam o número

**Dia sem `Água Cervejaria` lançada desconta zero.** É o único tratamento
possível — o que não foi medido não pode ser estimado —, mas o índice
daquele dia sai mais alto que a realidade. O script traz a consulta que
lista esses dias.

**Cervejaria maior que o FIT 100 dá índice negativo.** Não é operação, é
lançamento errado: índice negativo não existe. Optou-se por **deixar
aparecer** em vez de esconder o dia. Número absurdo na tela é pedido de
correção; dia que some em silêncio, ninguém procura. Mesmo princípio da
importação em lote, que devolve relatório em vez de engolir linha.

---

## 4. Validação

PostgreSQL 16 limpo, scripts `01` ao `17`, com o `17` rodado duas vezes.

| dia | dado | índice | conferência na mão |
|---|---|---|---|
| 01/09 | 900 FIT − 300 cerv. + 40 pipa + 260 Andina, 180.000 CXU | **0,881** | 0,881 |
| 02/09 | igual, sem cervejaria lançada | **1,174** | 1,174 |
| semana | soma 2.100 m³ ÷ 360.000 CXU | **1,027** | 1,027 |

O dia 01/09 valia **1,174** antes do expurgo: o desconto tirou 25% do
índice. E a semana continua saindo da soma do período, não da média dos
dias (0,881 e 1,174 dariam 1,028 por média — perto por acaso, com dois
dias de produção igual; com produção desigual a distância abre).

O caso negativo também foi exercitado: 200 de FIT contra 300 de
cervejaria devolve **−0,098**, visível, como se decidiu.
