# Registro — a apresentação, segunda versão

Sessão de 18 de setembro de 2026. Continuação de
`2026-09-17-apresentacao.md`.

---

## 1. A crítica

A primeira versão foi recusada: *"não ficou bom"*. Os pontos, todos
justos:

- não era editável;
- não dava para escolher um parâmetro e vê-lo em destaque;
- a comparação com o mês anterior ficou pequena;
- faltavam análises — dias fora da meta, comparação com a produção;
- parâmetros que não interessam à diretoria ocupavam espaço.

O erro de fundo: a v1 tratava o slide como **tabela de números**. Doze
parâmetros com o mesmo peso não dizem nada a quem tem vinte minutos. Um
slide de reunião precisa de **um assunto por vez**.

---

## 2. O que mudou

**Herói + cartões.** O parâmetro em foco ocupa a coluna esquerda inteira
— nome, número enorme, comparação, selo, dias fora da meta e o gráfico
do mês. Os demais ficam à direita como cartões. **Clicar num cartão
troca o destaque**: a apresentação se dirige, não se assiste.

O slide abre no parâmetro **que está fora da meta**, não no primeiro da
lista. Se nada estiver fora, abre no primeiro.

**A comparação virou leitura de diretoria.** De 12,5px para
clamp(21–28px), ao lado do número, com a seta colorida. É o que o
superior procura primeiro.

**Dias fora da meta** — contados no dia a dia contra o limite do
parâmetro: *"8 de 16 dias fora da meta"*. O fechamento esconde o
caminho; esse número mostra.

**Água por caixa produzida** — para os volumes da ETA, o valor do mês
dividido pela produção do mês, em L/caixa. É a leitura que liga o
consumo ao que a fábrica entregou.

**No topo de cada slide:** quantos parâmetros e quantos fora da meta.

---

## 3. Editável, e editável por quem usa

O botão **Editar** abre as caixas de seleção da unidade. Marcar e
desmarcar grava em `parametros.exibir_na_apresentacao` — **no banco**,
não na sessão. Vale para todo mundo, sobrevive a trocar de computador, e
tira de mim a lista do que aparece.

As exclusões pedidas já vão no script 22:

| unidade | fora dos slides |
|---|---|
| ETA | Turbidez, Cloro Semi |
| ETE Industrial | Nível TQ Químico, Nível TQ Equalização, pH Elev. Orgânico |

Elas continuam no painel — o que saiu foi da apresentação.

---

## 4. Um detalhe de contraste

No cartão em destaque, que é invertido, a seta de variação em vermelho
daria **1,7:1** contra o fundo escuro. Ali a seta vale pela forma, e a
cor passa a ser a do texto. O teste reprova se o vermelho voltar.

---

## 5. Validação

Playwright, monitor e celular:

- o destaque abre no parâmetro fora da meta;
- clicar num cartão troca o herói e marca o cartão;
- a comparação mede **mais de 20px**;
- "dias fora da meta" aparece, e "L por caixa produzida" bate com a
  conta feita à mão (30.800 m³ ÷ 5,5 milhões de caixas = 5,6 L);
- o parâmetro desmarcado no cadastro não aparece;
- desmarcar pelo Editar **grava um PATCH no banco** e some do slide;
- nada de vermelho dentro do cartão escuro;
- no celular: sem rolagem lateral, barra em uma linha, fonte do eixo
  acima de 9px, e o slide rola em vez de cortar.
