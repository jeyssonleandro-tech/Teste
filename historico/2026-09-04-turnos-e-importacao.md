# Registro — importação em lote e lançamento por turno

Sessão de 4 de setembro de 2026. Continuação de
`2026-09-03-limites-e-identidade-visual.md`.

---

## 1. Importação por planilha

Digitar meses de histórico no formulário é inviável. A carga passa por uma
**tabela de recepção** de texto puro, e não direto para `leituras`: a
planilha traz nomes de unidade e parâmetro, a tabela guarda códigos
internos, e alguém precisa traduzir.

**Formato definido:** quatro colunas obrigatórias — `data`, `unidade`,
`parametro`, `valor` — mais `observacao` e `turno` opcionais. Uma linha por
medição, não uma coluna por parâmetro: é o formato do banco, e uma planilha
larga teria colunas vazias em quase toda linha.

A função `importar_leituras()` devolve **relatório**: toda linha rejeitada
volta com o motivo e um exemplo do que estava escrito. Linha que some em
silêncio é o pior desfecho possível numa carga de dados.

Aceita data em `03/08/2026` e `2026-08-03`, e número com vírgula ou ponto —
o que sai do Excel brasileiro e do Planilhas Google. Reimportar corrige em
vez de duplicar.

**Armadilha documentada:** o "CSV" comum do Excel brasileiro grava com
ponto e vírgula, e sem UTF-8 os acentos quebram — *Sanitária* vira
*Sanit?ria* e a unidade não é encontrada. Tem que ser
`CSV UTF-8 (delimitado por vírgulas)`.

---

## 2. Lançamento por turno

Turnos de 12 horas: 1º das 06h às 18h, 2º das 18h às 06h.

### As perguntas que precederam a decisão

Antes de mexer, foram postas sete perguntas ao supervisor — porque
segregar turno muda a regra fundamental do banco (uma medição por unidade
+ parâmetro + dia) e **dobra o trabalho de lançamento**. Isso só se paga se
alguém de fato olhar os turnos separadamente.

| Decisão | Escolha |
|---|---|
| Onde se aplica | Só ETE Industrial e ETE Sanitária — característica da **unidade**, não do parâmetro |
| Consolidação | A regra de cada parâmetro: soma, média ou último |
| Painel | Consolidado por padrão, com opção de abrir um turno |
| Alerta | Qualquer turno fora da faixa acende |
| Turnos | Dois, fixos |
| Histórico | Tudo que existia vira 1º turno |

### A regra da virada da meia-noite

Só o 2º turno cruza a meia-noite. **A medição pertence ao dia em que o
turno começou** — leitura das 2h da manhã do dia 5, do turno que entrou às
19h do dia 4, é lançada como dia 4. Sem isso o turno da noite ficaria
partido em dois dias e a soma do volume sairia pela metade.

O formulário aplica sozinho: quem abre de madrugada e escolhe o 2º turno
encontra a data do dia anterior já preenchida.

### Um nível a mais na cadeia de agregação

```
leituras (turno) → dia consolidado → semana / mês
```

O dia passou a ser a unidade atômica. Antes, semana e mês agregavam
leituras cruas; com turno isso daria peso dobrado ao dia que teve os dois
turnos sobre o dia que teve um só.

### Consequência para a ETE Sanitária

Os parâmetros dela comparavam pelo **último valor** do dia. Com dois
turnos, um 1º turno ruim ficaria escondido atrás do 2º — contrário à
decisão de "qualquer turno acende". Passaram a comparar pelos extremos.

---

## 3. O gráfico: sobreposição virou seleção

A primeira versão sobrepunha as duas séries. O supervisor corrigiu o rumo:
**uma linha só, sempre**, e um seletor de três posições — Consolidado, 1º,
2º — para escolher qual se vê.

Muda o que a tela responde: de "como os turnos se comparam" para "como foi
o dia, e se eu quiser, como foi um turno". É a pergunta que ele faz no dia
a dia.

Escolher um turno filtra a **unidade inteira** — destaque, lista e tabela.
Meia tela num recorte e meia noutro seria pior que não ter o recorte. As
abas continuam saindo do consolidado, senão a ETA e a Represa sumiriam do
menu ao selecionar um turno.

---

## 4. ETE Sanitária ampliada

| Parâmetro | Unidade | Agregação | Cadência |
|---|---|---|---|
| Volume Tratado | m³ | soma | diária |
| Vazão de tratamento | m³/h | média | diária |
| DQO Eflu Bruto | mg/L | último | diária |
| DQO Eflu Tratado | mg/L | último | diária |
| Nitrogênio | mg/L | último | **semanal** |
| Fósforo | mg/L | último | **semanal** |

A coluna `periodicidade` não restringe o banco: serve para o formulário
marcar o campo e o operador parar de achar que esqueceu de preencher.

---

## 5. Percalços do dia

| Erro | Causa | Solução |
|---|---|---|
| `42P01: relation "public.importacao_leituras" does not exist` ao rodar o 12 | O script 11 nunca tinha sido rodado, e o 12 altera a tabela dele | Criar a tabela primeiro. O Supabase executa o script inteiro numa transação, então nada tinha sido aplicado pela metade |

Reforço do padrão: **um script por vez, na ordem numérica.** Eles se
apoiam uns nos outros, e pular um faz o seguinte falhar num ponto sem
relação óbvia com a causa.

### Um defeito que o teste pegou antes do usuário

A consulta que descobre quais unidades usam turno podia **derrubar o painel
inteiro** quando a coluna `usa_turno` ainda não existe — que é exatamente o
estado de quem baixa o arquivo novo antes de rodar o script. Recurso
opcional não derruba a tela: passou a falhar em silêncio.

---

## 6. Em aberto

| Item | Esperando |
|---|---|
| Limites dos novos parâmetros da ETE Sanitária | Valores de conformidade, se houver |
| `09_excluir_usuario.sql` | Rodar quando puder |
| Dados retroativos | O supervisor subir a planilha |
| Liberação do `github.io` | Resposta da TI |
| Separar leitor de lançador | Antes de dar login a fornecedor |
| Índice de Água | A fórmula |
