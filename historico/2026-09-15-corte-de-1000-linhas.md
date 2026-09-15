# Registro — o dia lançado que não aparecia

Sessão de 15 de setembro de 2026. Continuação de
`2026-09-14-expurgo-da-cervejaria.md`.

---

## 1. O sintoma

Os dados de 13/09 foram lançados e não apareciam no painel. No banco
estavam lá: 28 leituras naquela data.

## 2. A causa

O painel buscava a série assim:

```
/rest/v1/vw_leituras_diarias?select=…&order=data.asc
```

Sem filtro e sem limite. **O REST do Supabase corta a resposta em 1000
linhas** por padrão, e a ordem era crescente: o que voltava eram as 1000
leituras **mais antigas**, e os dias recentes caíam fora — em silêncio,
sem erro, sem aviso.

Com 22 a 33 leituras por dia, 1000 linhas ≈ 40 dias. Os lançamentos
começaram em agosto: o teto foi atingido em setembro, e o painel passou a
mostrar um histórico congelado sem que nada acusasse.

**O erro de projeto não foi o limite — foi pedir tudo.** Uma tela que
mostra um mês não tinha por que carregar o histórico inteiro a cada
abertura.

---

## 3. O conserto

A janela passou a morar no banco, não no navegador. Todo modo consulta
por intervalo de datas:

| modo | janela |
|---|---|
| diário | os dias do mês de referência |
| semanal | as **quatro** semanas que fecham nele — 28 dias, abaixo dos 30 pedidos |
| mensal | os **doze** meses que terminam nele |

O menu de período, que oferecia "14 dias / 30 dias / 90 dias / todo o
histórico", virou **seletor de mês** — doze meses para trás. É a unidade
em que a operação pensa, e é o que garante consulta pequena.

`organizar()` deixou de cortar a série no navegador. Cortar duas vezes —
uma no banco, outra na tela — era o que permitia a um dia lançado sumir
sem deixar rastro.

---

## 4. O alarme que faltava

A consulta passa a pedir `Prefer: count=exact` e a comparar o total com o
que veio. Se algum dia a resposta vier cortada de novo, o painel **diz**:

> O banco tinha 3500 linhas para este período e devolveu 1000. Escolha um
> período menor — o que está no gráfico não é tudo.

Silêncio foi o que custou caro aqui. Resposta truncada agora tem voz.

---

## 5. Acumulado do mês

Índice de Água, Índice de Água Cervejaria e Vazão de captação ganham a
média do mês corrente **no número em destaque**. A série do gráfico, a
lista e a tabela seguem com o valor de cada dia ou semana.

A primeira versão acumulava a série inteira — cada ponto do gráfico virava
o acumulado até ali. Foi corrigido no mesmo dia: o pedido era um número,
não uma curva. Um gráfico de acumulado só sobe e esconde justamente o que
o operador precisa ver, que é o dia que saiu da linha.

Ao lado do número do mês fica o do último período (*"dia 14/09/2026:
1,2"*), para as duas leituras conviverem sem se confundir. No mensal nada
muda: o valor do mês já é o fechamento.

A marcação é do banco (`parametros.acumula_mes`), não do HTML.

**A conta do acumulado de uma razão não é média simples.** O acumulado do
índice é a soma da água dividida pela soma da produção, o que equivale a
uma média dos valores **ponderada pela produção de cada dia**. O painel
busca essa produção na `vw_indice_agua` e pondera. Assim os fatores de
conversão continuam só no banco, e o navegador não repete constante
nenhuma. Sem peso disponível, cai para média simples — que é o certo para
a vazão de captação.

---

## 6. Validação

Playwright contra um Supabase falso que **filtra as linhas pela janela
pedida na URL** — assim o teste falha se a consulta esquecer o filtro:

- abre no mês corrente, com o rótulo do mês no controle;
- toda consulta de série leva `gte`/`lt` de data;
- o diário de setembro não traz dia de agosto;
- trocar o mês refaz a consulta e muda o eixo;
- a janela semanal mede 28 dias;
- a mensal vai de outubro/2025 a setembro/2026;
- o índice traz o rótulo da média do mês no destaque;
- **a série do gráfico continua oscilando** — o teste falha se ela virar
  uma curva sempre crescente, que é a assinatura de série acumulada;
- o número em destaque bate com a média ponderada calculada à mão.
