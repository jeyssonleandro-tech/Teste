# Registro — datas impressas uma sobre a outra

Sessão de 17 de setembro de 2026, à tarde.

---

## O sintoma

No eixo do gráfico, `15/09` e `16/09` saíam sobrepostos — o penúltimo
rótulo e o último, colados.

## A causa

As datas do eixo eram desenhadas de `passoRot` em `passoRot`, **mais o
último período, sempre**:

```js
if (i % passoRot !== 0 && !ultimo) return "";
```

O "sempre" é certo — a data mais recente é a mais procurada. O erro era
não abrir espaço para ela. Quando `(qtd - 1)` não é múltiplo do passo, o
último rótulo cai a um ponto de distância de uma marca regular, e os dois
se atropelam.

Não era caso raro: com 12, 14, 16, 17… dias o defeito aparece em várias
larguras de tela. Aparecia desde o primeiro desenho do gráfico, em agosto,
e só ficou visível agora que a janela é o mês corrente e a quantidade de
dias varia todo dia.

## O conserto

O último rótulo continua garantido; **quem ficar perto demais dele cede o
lugar**:

```js
const indices = [];
for (let i = 0; i < ultimoI; i += passoRot) indices.push(i);
while (indices.length
       && x(ultimoI) - x(indices[indices.length - 1]) < LARGURA_ROTULO) indices.pop();
indices.push(ultimoI);
```

## Validação

O teste varre **nove quantidades de dias** (12 a 31) por **sete larguras
de tela** (1440 a 390px) e reprova se dois rótulos encostarem, ou se o
último dia sumir do eixo.

Rodado contra o código antigo, ele reproduz o caso da foto:

```
✗ rótulos colados (16 dias, 980px): 15/09 e 16/09
```

Com o conserto, as 63 combinações passam.
