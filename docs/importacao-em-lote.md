# Subir dados retroativos por planilha

Para poucos dias, o formulário é mais rápido. Para semanas ou meses de
histórico, é este o caminho.

---

## O formato da planilha

**Quatro colunas obrigatórias, uma linha por medição.** Nesta ordem, com
estes nomes exatos na primeira linha:

| data | unidade | parametro | valor | observacao |
|---|---|---|---|---|
| 2026-08-03 | ETA | Volume Tratado | 708 | |
| 2026-08-03 | ETA | Turbidez | 6.36 | |
| 2026-08-03 | ETE Industrial | pH Equalizado | 6.8 | |

As colunas `observacao` e `turno` são opcionais.

**Turno** só vale para ETE Industrial e ETE Sanitária: `1` para 06h–18h,
`2` para 18h–06h. Em branco, numa dessas unidades, entra como 1º turno.
Nas outras unidades a coluna é ignorada.

E vale a regra da virada: a medição pertence ao dia em que o **turno
começou**. Uma leitura das 2h da manhã do dia 5, do turno que entrou às
19h do dia 4, é lançada como dia 4.

**Por que uma linha por medição e não uma coluna por parâmetro:** é o
formato que o banco usa. Cada unidade tem parâmetros diferentes; uma
planilha larga teria colunas vazias em quase toda linha, e o dia em que
você cadastrasse um parâmetro novo exigiria mudar a estrutura.

### Como converter sua planilha atual

Se a sua planilha é larga — uma coluna por parâmetro —, o Excel converte
em cinco cliques, sem digitar nada:

1. Selecione a área de dados, com os títulos
2. **Dados → Obter e Transformar → Da Tabela/Intervalo**
3. No editor, selecione **só** a coluna de data
4. **Transformar → Não Dinamizar Outras Colunas**
5. **Página Inicial → Fechar e Carregar**

Sai exatamente o formato longo. Depois é só renomear as colunas e
acrescentar a coluna `unidade`.

### Regras de preenchimento

| Campo | Aceita | Cuidado |
|---|---|---|
| `data` | `2026-08-03` ou `03/08/2026` | Uma data por linha, do dia da medição |
| `unidade` | ETA, ETE Industrial, ETE Sanitária, Represa, Produção | Tem que bater com o cadastro |
| `parametro` | o nome exato cadastrado | Maiúscula/minúscula não importa; acento importa |
| `valor` | `6.36` ou `6,36` | Um número por linha. Vazio é ignorado |
| `observacao` | texto livre | **Nunca** nome, CPF, telefone ou e-mail |

**Lance dia a dia, não o fechamento do mês.** O semanal e o mensal são
calculados pelo banco a partir dos dias. Um total mensal lançado num único
dia estraga a média e os extremos que alimentam os alertas de limite.

---

## Salvando o arquivo

Este é o passo que mais dá problema. **Salve como `CSV UTF-8 (delimitado
por vírgulas)`** — não o "CSV" comum.

Dois motivos:

- O CSV comum do Excel brasileiro grava com **ponto e vírgula**, e o
  importador espera vírgula
- Sem UTF-8, os acentos viram símbolos: *Sanitária* vira *Sanit�ria*, e
  aí a unidade não é encontrada

**Confira antes de importar:** abra o arquivo no Bloco de Notas. Você deve
ver vírgulas separando os campos e os acentos corretos. Se vir ponto e
vírgula, use o Planilhas Google — ele exporta CSV correto sempre.

---

## Importando

1. Supabase → **Table Editor** → tabela `importacao_leituras`
2. Botão **Insert → Import data from CSV**, escolha o arquivo
3. Abra o **Editor SQL** e rode:

```sql
select * from public.importar_leituras();
```

Ele devolve um relatório assim:

| situacao | linhas | exemplos |
|---|---|---|
| gravadas | 340 | linhas inseridas ou corrigidas em leituras |
| parâmetro não encontrado nessa unidade | 12 | Vazão de Entrada (Represa) |

4. **Se houver linhas rejeitadas**, corrija a planilha, esvazie a recepção
   e repita:

```sql
truncate public.importacao_leituras;
```

5. **Quando estiver tudo certo**, esvazie a recepção do mesmo jeito. Ela é
   área de passagem, não de arquivo.

---

## O que a importação faz por você

- **Reimportar corrige, não duplica.** Se já existir lançamento para a
  mesma unidade + parâmetro + dia, o valor é atualizado. Você pode rodar
  duas vezes sem sujar o banco.
- **Nada some em silêncio.** Toda linha rejeitada aparece no relatório com
  o motivo e um exemplo do que estava escrito.
- **Aceita os dois formatos de data e de número** que saem do Excel
  brasileiro e do Planilhas Google.
- **Insumo oculto também se importa.** `Caminhão Pipa` (ETA) e
  `Volume de produção L5` (Produção) entram pela planilha como qualquer
  outro parâmetro, mesmo não aparecendo no painel — eles alimentam os
  índices de água.
- **Parâmetro calculado não se importa.** `Índice de Água` e
  `Índice de Água Cervejaria` são conta, não medição: o banco os recusa se
  aparecerem na planilha, com linha própria no relatório.

---

## Depois de importar

Abra o painel no modo **Mensal** e confira mês a mês. É a visão onde erro
de data salta à vista: um lançamento no mês errado aparece isolado, longe
da linha.
