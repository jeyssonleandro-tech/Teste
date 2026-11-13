---
name: consolidado-atrasos
description: Gera a planilha mensal de consolidado de atrasos na entrada dos colaboradores a partir dos espelhos de ponto aglutinados em .md (PDF convertido). Use quando o usuário enviar os espelhos de ponto de um mês e pedir o levantamento, cálculo ou consolidado de atrasos, ou digitar /consolidado-atrasos.
---

# Consolidado mensal de atrasos

Responda sempre em português do Brasil. Datas e horários seguem o fuso de São Paulo.

## Entrada esperada

Um arquivo `.md` com os espelhos de ponto de todos os colaboradores aglutinados,
no mesmo formato do material de setembro/2026: PDF do sistema de ponto convertido
para Markdown, com o cabeçalho "ESPELHO DE PONTO", o quadro "Códigos de Horários (CH)"
e a tabela diária com as colunas Data, CH, Marcações, Jornada e Justificativa.

Se o usuário mandar o PDF em vez do `.md`, avise que o script lê o `.md` convertido
e pergunte se ele consegue enviar nesse formato antes de tentar outra coisa.

## Regras do cálculo (já validadas com o usuário)

- **Atraso = primeiro horário da coluna Jornada − horário de entrada do CH do dia.**
  Exemplo: escala 06:00, ponto 06:32 = 32 min.
- **Conta todo minuto, sem tolerância.** Use `--tolerancia N` só se o usuário pedir.
- **Considera só o atraso na entrada.** Saída antecipada não entra.
- O CH é lido dia a dia, o que respeita trocas de escala no meio do mês.
- Marcações incluídas manualmente e aprovadas valem como estão na Jornada.
- Folga, DSR, COMP, feriado, licenças, acidente, treinamento e trabalho externo não geram atraso.
- **Abono no espelho** (ex.: "Abono # Ausência Op.") zera o atraso do dia: vem marcado
  "Sim" na coluna "Desconsiderar atraso?".
- **Meio turno sem justificativa** (entrada perto das 12:00 num dia de ausência
  operacional, como a decisão de out/2026): **pergunte ao gestor** antes de contar.
  Se ele mandar desconsiderar, lance um ajuste `desconsiderar`.
- O horário de cada CH vem do quadro "Códigos de Horários" dos próprios espelhos.
  Em setembro/2026 eram 0026 = 08:00, 0030 = 06:00 e 0032 = 18:00.

## Ajustes informados pelo gestor

O gestor costuma completar pontos em branco (saídas, atestados etc.). Grave-os num CSV
**no scratchpad** (nunca no repositório) e passe com `--ajustes`:

```csv
colaborador;data;tipo;valor
Fulano de Tal;09/10/2026;saida;06:02
Fulano;29/10/2026;justificativa;Atestado médico
01234567;25/10/2026;desconsiderar;Motivo informado pelo gestor
```

- `colaborador`: matrícula ou parte do nome (acentos e maiúsculas não importam).
- `tipo`: `saida` e `entrada` (hh:mm), `justificativa` (texto) ou `desconsiderar` (motivo).
- Só `entrada` e `desconsiderar` mudam o atraso. Saída e justificativa ficam registradas
  na planilha. Diga isso ao gestor quando o ajuste dele não alterar o total.
- O script para com erro se um ajuste não casar com nenhum colaborador ou dia.

## Passo a passo

0. **Antes de calcular, leia o `.md` e pergunte ao gestor** sobre o que for ambíguo:
   atrasos muito grandes (horas), meio turno, CH novo, dias faltando. O usuário pediu
   para ser acionado antes de qualquer resposta quando houver dúvida.

1. **Rode o script** (instale o openpyxl antes, se faltar: `pip install openpyxl`):

   ```bash
   mkdir -p saidas
   python3 .claude/skills/consolidado-atrasos/scripts/gerar_consolidado.py "<arquivo.md>" \
     --saida "saidas/Consolidado_Atrasos_<Mes>_<Ano>.xlsx" [--ajustes "<scratchpad>/ajustes.csv"]
   ```

   O script grava a planilha e imprime um JSON com o período, as escalas encontradas,
   os totais por colaborador e os pontos de atenção.

2. **Confira o JSON antes de entregar:**
   - Os nomes estão inteiros e corretos? Compare com o cabeçalho do `.md`.
   - Cada colaborador tem os dias do mês? Se aparecer "Dia não encontrado", olhe
     a linha no `.md` e diga ao usuário qual é.
   - Algum CH novo usou a entrada padrão? Pergunte ao usuário o horário de entrada.
   - Amostre de 3 a 5 dias com atraso, de colaboradores diferentes, e confirme no
     `.md` que entrada e escala batem.
   Se algo estiver errado, corrija o script, rode de novo e repita a conferência.

3. **Entregue a planilha pelo chat** com `SendUserFile` (`display: "attach"`).

4. **Responda com:** a tabela-resumo (colaborador, escala, dias trabalhados, dias
   com atraso, total em min e h:mm, maior atraso), o total da equipe, os destaques
   do mês e os pontos de atenção que o usuário deve conferir no espelho original.

## Cuidados

- **Nunca faça commit nem push da planilha nem do `.md`.** Eles têm dados pessoais
  dos colaboradores, e o usuário pediu que não fossem para o GitHub. A pasta
  `saidas/` está no `.gitignore`.
- Abas da planilha: **Resumo** (ordenado do maior para o menor atraso),
  **Detalhe diário** (com saída registrada e a coluna "Desconsiderar atraso?", que o
  gestor pode editar no Excel), **Pontos de atenção** e **Escalas**. A tolerância fica numa
  célula da aba Escalas e recalcula tudo quando alterada.
- O LibreOffice deste ambiente pode não abrir arquivos. A planilha já sai marcada
  para recalcular ao abrir no Excel. Para conferir as fórmulas, use `pycel`
  (`pip install pycel`) e compare com o JSON.
