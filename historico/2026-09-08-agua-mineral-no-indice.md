# Registro — água mineral no Índice de Água

Sessão de 8 de setembro de 2026. Continuação de
`2026-09-08-redesenho-do-lancamento.md`.

---

## 1. O que estava errado

O numerador do Índice de Água não contemplava o **volume de água
mineral**. A conta ficava menor do que a realidade — e menor de um jeito
que passa despercebido, porque continua dando um número plausível.

Fórmula corrigida:

```
Índice de Água = (Volume FIT 100 + Caminhão Pipa + Volume Andina 1)
                 ÷ (Volume de produção × 5,678)
```

O Índice de Água Cervejaria não muda.

---

## 2. As quatro mudanças

| o quê | como |
|---|---|
| `Volume Tratado` (ETA) → `Volume FIT 100` | `update` no nome |
| `Volume Andina 1` (ETA, m³) | novo insumo, oculto no painel |
| `Vazão de Entrada` (ETA) | `ativo = false` |
| numerador do índice | mais uma parcela na `vw_indice_agua` |

O rename só atinge a ETA. A ETE Industrial e a ETE Sanitária têm um
`Volume Tratado` próprio, que continua com esse nome.

**Nada de histórico se perdeu.** `leituras` aponta para o *id* do
parâmetro, não para o nome: tudo o que já foi medido continua ligado ao
mesmo registro, agora com outro rótulo.

**`Vazão de Entrada` foi desativada, não apagada.** Apagar exigiria
destruir as leituras junto. Desativado, o parâmetro some do formulário, do
painel e da importação, e volta com um `ativo = true` se um dia fizer
falta.

---

## 3. O ponto em aberto: o 5,678

A fórmula veio escrita como `/ volume de produção`, sem o fator de
conversão. Ele foi **mantido**, e a decisão está registrada aqui porque
muda o resultado por inteiro:

- a produção é lançada em **CXU**, e o índice é **L/L**;
- sem converter caixa em litro, o índice sairia 5,678 vezes maior — perto
  de **7,0**, contra um teto de **1,33**;
- o próprio teto é a evidência: uma meta de 1,33 só faz sentido com o
  denominador em litros.

Se a intenção era mesmo tirar o fator, é uma linha na view.

---

## 4. Validação

PostgreSQL 16 limpo, scripts `01` ao `15`, com o `15` rodado duas vezes
(é idempotente). `create or replace view` preservou as views do dashboard
que dependem da `vw_indice_agua` — as colunas são as mesmas.

Com um dia semeado (900 + 40 + 260 m³ de água, 180.000 CXU):

| conferência | resultado |
|---|---|
| índice calculado pelo banco | 1,174 |
| mesma conta na mão | 1,174 |

E no painel da ETA: os dois índices e o `Volume FIT 100` visíveis;
`Caminhão Pipa` e `Volume Andina 1` ausentes; `Vazão de Entrada` fora de
tudo.
