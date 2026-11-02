# Registro — dois índices de água, mesma escala

Sessão de 17 de setembro de 2026. Continuação de
`2026-09-15-corte-de-1000-linhas.md`.

---

## 1. O que mudou

O índice da cervejaria deixou de ser *"quanta água a cervejaria gasta por
caixa da linha 5"* e passou a ser o índice da **fábrica inteira**:

```
Índice de Água s/ Cerveja = ((FIT 100 − Água Cervejaria) + Pipa + Andina 1) × 1000
                            ÷ (Volume de produção × 5,678)

Índice de Água c/ Cerveja = ((FIT 100 + Pipa + Andina 1) × 1000)
                            ÷ (Volume de produção × 5,678)
```

O de sem cerveja não mudou.

## 2. Por que o par funciona

Com o **mesmo denominador** nos dois, a diferença entre eles é exatamente
a água da cervejaria — e os dois passam a viver na mesma escala. Antes,
comparar um com o outro não dizia nada: denominadores diferentes, unidades
de produção diferentes.

O teste confere essa propriedade diretamente: `c/ cerveja` menos
`s/ cerveja` tem de dar a Água Cervejaria do dia.

## 3. Os nomes mudaram

`Índice de Água` → **`Índice de Água s/ Cerveja`**
`Índice de Água Cervejaria` → **`Índice de Água c/ Cerveja`**

A tela precisa dizer o que cada número é, e "Índice de Água Cervejaria"
passaria a mentir: não é mais o índice da cervejaria, é o da fábrica com a
cervejaria dentro.

Nada de histórico se perde: índice é calculado, não tem leitura gravada.
E nenhum HTML foi tocado — os nomes vêm do banco.

## 4. Um insumo ficou órfão

`Volume de produção L5` era o denominador do índice antigo da cervejaria e
agora não alimenta conta nenhuma. **Continua ativo**: desativar é decisão
de quem lança, e o comando está comentado no fim do script. Mas é um campo
que a operação preenche todo dia sem destino — vale decidir.

## 5. Validação

PostgreSQL 16 limpo, scripts `01` ao `19`, com o `19` rodado duas vezes.

| | água no numerador | índice | na mão |
|---|---|---|---|
| s/ cerveja | 900 m³ | **0,881** | 0,881 |
| c/ cerveja | 1.200 m³ | **1,174** | 1,174 |
| diferença | 300 m³ | = Água Cervejaria do dia ✓ | |

O painel lista os dois na ordem certa (5 e 6), o teto de 1,33 seguiu com o
`s/ Cerveja`, e o acumulado do mês acompanhou os dois nomes novos.

---

## 6. Pluviometria: o mês inteiro

Chuva de um dia não diz nada sozinha; o que a operação acompanha é quanto
choveu no mês. A Pluviometria entrou na mesma marcação `acumula_mes`.

Só que somar chuva e tirar média de vazão são contas diferentes — e a
resposta já estava no banco. **O acumulado passou a seguir a regra de
agregação que cada parâmetro já tem**, a mesma que o banco usa para fechar
semana e mês:

| agregação | número do mês | quem |
|---|---|---|
| `soma` | total do período | Pluviometria |
| `razao` | soma ÷ soma (média ponderada pela produção) | os dois índices de água |
| resto | média dos períodos | Vazão de captação |

Nenhuma coluna nova: a regra já existia. O rótulo do destaque acompanha —
*"total de setembro de 2026"* para a chuva, *"média de setembro de 2026"*
para a vazão.

A visão diária passou a trazer `agregacao` na consulta; sem ela o painel
não teria como saber qual das três contas aplicar.

**Validado:** o total da chuva no mês bate com a soma feita à mão, a vazão
segue como média, e cada uma traz o rótulo certo.

---

## 7. Teto do c/ cerveja e a saída da L5

**1,40 L/L** para o Índice de Água c/ Cerveja, com `limite_base =
'periodo'` — como o parâmetro é de acumulado, o número julgado é a média
do mês. É o fechamento que a meta cobra, não o pior dia. O par fica
completo: 1,33 sem cerveja, 1,40 com.

**`Volume de produção L5` foi desativado, não apagado.** Apagar a linha de
`parametros` esbarraria no `ON DELETE RESTRICT` de `leituras` e só passaria
depois de destruir todas as medições já lançadas. Desativado, ele some do
formulário, do painel e da importação, e o que a operação já mediu
continua no banco — reversível com um `ativo = true`.

Agora são dois parâmetros inativos: `Vazão de Entrada` (ETA) e
`Volume de produção L5` (Produção).
