# Registro — índices de água e insumos ocultos

Sessão de 4 de setembro de 2026. Continuação de
`2026-09-04-turnos-e-importacao.md`.

---

## 1. O pedido

Lançar valores que **não** devem aparecer no dashboard, para que o Índice de
Água possa ser calculado a partir deles.

Duas fórmulas acordadas:

```
Índice de Água           = (Volume Tratado + Caminhão Pipa) ÷ (Volume de produção × 5,678)
Índice de Água Cervejaria = Água Cervejaria ÷ (Volume de produção L5 × 5,678)
```

| insumo | unidade | situação |
|---|---|---|
| `Volume Tratado` | ETA, m³ | já cadastrado, visível |
| `Água Cervejaria` | ETA, m³ | já cadastrado, visível |
| `Caminhão Pipa` | ETA, m³ | **novo**, oculto |
| `Volume de produção` | Produção, CXU | já cadastrado, visível |
| `Volume de produção L5` | Produção, CXU | **novo**, oculto |

`5,678` é o número de litros por caixa unitária.

---

## 2. Separar "o que se lança" de "o que se mostra"

Duas colunas novas em `parametros`, e não uma tabela paralela:

- `exibir_no_painel` — o insumo é lançado, auditado e importado como
  qualquer outro parâmetro; só fica fora do dashboard.
- `calculado` — o parâmetro é conta, não medição: fora do formulário de
  lançamento e fora da importação.

Uma tabela separada para os insumos custaria RLS própria, importação
própria e formulário próprio — três lugares para o mesmo dado divergir.
Uma coluna booleana resolve sem duplicar nada.

Hoje `Caminhão Pipa` e `Volume de produção L5` estão ocultos. Esconder
outro insumo é uma linha:

```sql
update public.parametros set exibir_no_painel = false
 where nome = 'Volume de produção' and aplica_a_tipo = 'Produção';
```

---

## 3. A conversão de unidade

O numerador está em m³ e o denominador vira litros (CXU × 5,678). Por isso
o numerador é multiplicado por **1000**. Sem essa conversão o índice sairia
mil vezes menor — `0,003` em vez de `2,9 L/L`. Os dois fatores ficam
isolados na `vw_indice_agua`, num lugar só.

---

## 4. Razão não se agrega por média

Regra já registrada em agosto, e agora aplicada: o índice do período é a
**soma da água dividida pela soma da produção**, nunca a média dos índices
diários. Cada granularidade é calculada direto das leituras.

Diferença medida no teste local, com dois dias de dados:

| forma | resultado |
|---|---|
| soma ÷ soma (correto) | **3,581** |
| média dos índices diários (errado) | 4,967 |

Um erro de 39% — e sempre para cima, porque o dia de baixa produção pesa
igual ao dia cheio.

---

## 5. Validação

Os catorze scripts foram executados numa instância PostgreSQL 16 local, do
`01` ao `14`, sobre um banco vazio com `auth.users` e os papéis do Supabase
simulados. Depois, com dados semeados:

- os dois índices conferidos na mão nas três granularidades;
- `Caminhão Pipa` e `Volume de produção L5` confirmados ausentes do painel;
- importação em lote testada com sete linhas — os dois insumos ocultos
  entraram, os dois índices foram recusados com nome próprio no relatório,
  e nenhuma leitura calculada foi gravada;
- script rodado duas vezes seguidas, para provar que é idempotente.

---

## 6. Dia incompleto não entra no período

Um dia com água lançada mas sem produção somaria água ao numerador da
semana sem somar nada ao denominador — e inflaria o índice do período
inteiro por causa de um lançamento em falta. No teste, um dia sem o L5
lançado levava o índice da cervejaria de 1,057 para 2,043.

Por isso o cálculo só considera dias com **os dois lados** lançados.
Semana com menos dias e certa é melhor que semana cheia e errada.

---

## 7. O teto: 1,33 L/L

Vale para o Índice de Água (sem cervejaria). Cadastrado como
`limite_superior`, com `limite_base = 'periodo'` — o valor
comparado é o que está na tela. Num índice é o certo: a semana que fecha em
1,28 está dentro da meta mesmo tendo tido um dia ruim, e é o fechamento do
período que a meta cobra. Não há limite inferior: gastar menos água que a
meta não é desvio.

O teto também confirma a conversão de m³ para litros. Com 1,33 L/L
esperado, o índice tem de sair na casa da unidade — e sai. Sem o fator
1000 sairia em 0,001, três ordens de grandeza fora da meta.

---

## 8. Em aberto

- **Teto do Índice de Água Cervejaria** — ainda sem meta cadastrada. Sai
  em cinza no painel até haver uma.
- **Conferir a conversão** com um dia real de operação, antes de apresentar
  o número a terceiros.
