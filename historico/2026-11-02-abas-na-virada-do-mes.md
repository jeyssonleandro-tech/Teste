# ETA e Represa sumiram do painel na virada do mês

Data: 02/11/2026 (America/Sao_Paulo)

## O que aconteceu

Às 09h35 do dia 02/11 o painel mostrava só as abas ETE Industrial e
ETE Sanitária. Nenhum dado foi perdido.

## Causa

O painel abre no mês do último lançamento feito no banco. A ETE
Industrial já tinha o turno do dia 01/11 lançado, então o painel abriu
em novembro. As abas eram montadas **a partir dos dados do mês**: a ETA
e a Represa ainda não tinham lançamento em novembro e, por isso,
deixaram de ter aba.

O defeito nasceu com a mudança de 15/09, que passou a filtrar a consulta
pelo mês vigente. Antes as abas vinham de uma janela maior e o problema
não aparecia. Vai acontecer em toda virada de mês até as quatro
unidades lançarem o dia 01.

## Correção (`index.html`)

- As abas saem do **cadastro** (`unidades` ativas, menos Produção), não
  dos dados. Unidade sem lançamento no mês continua com a aba.
- Ao abrir uma unidade sem lançamento no mês, a tela diz isso, mostra a
  data do último lançamento e oferece um botão para ir direto ao mês
  dele (por exemplo, "Ver Outubro 2026").
- Defeito antigo encontrado no caminho: o seletor de turno aparecia na
  ETA e na Represa, que não têm turno, porque o `display: inline-flex`
  do CSS vencia o atributo `hidden`. Agora `[hidden]` sempre esconde.
- "1 dias" passou a ser "1 dia".

## Teste

`virada.mjs` (Playwright, relógio fixo em 02/11/2026 09h35): outubro
completo nas quatro unidades e só o dia 01/11 na ETE Industrial. A versão
anterior reproduz o defeito (uma aba só); a nova mostra as quatro, o
aviso da ETA com 31/10/2026 e o botão leva a outubro com 31 dias.
Rodado em monitor (1280 px) e celular (390 px).
