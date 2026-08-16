# Financeiro do Casal

Painel do orçamento mensal do casal em arquivo único (`index.html`), sem
dependências externas — basta abrir no navegador. Os números vêm da planilha
`Financeiro_Casal.xlsx` (abas **Contas Fixas** e **Investimentos**) e podem ser
atualizados carregando o CSV exportado do Google Sheets, lido no próprio
navegador.

## A ideia central

A planilha mistura três coisas na mesma coluna de despesas: contas que consomem
dinheiro, aportes que só mudam de bolso, e a renda. O painel separa:

```
renda 17.626,83 − custo de vida 10.560,28 − aportes 6.500,00 = sobra 566,55
```

Com isso a taxa de poupança do casal aparece: **40,1%** da renda fica com vocês
(aportes + sobra).

## O que cada cartão mostra

| Cartão | Conteúdo |
|---|---|
| Indicadores | Renda, custo de vida, aportes e sobra do mês, cada um com seu peso na renda |
| Para onde vai a renda | Barra empilhada: custo de vida × aportes × sobra, com a taxa de poupança |
| De onde vem a renda | Quanto cada salário e o aluguel do apartamento representam |
| Os dois pagamentos | Renda, custo de vida e aportes no dia 15 e no dia 30, com a sobra de cada data |
| Custo de vida por categoria | Sete categorias derivadas do nome do lançamento; o tooltip abre os itens |
| Assinaturas do cartão | As cobranças recorrentes e quanto representam da fatura lançada |
| Investimentos | Saldo e rendimento por conta, cor por objetivo, e quantos meses de custo de vida a reserva cobre |

## Classificação automática

Cada linha da planilha é classificada pelo nome:

- **Aporte** — começa com `Inv.`, ou contém `investimento`, `aporte`, `reserva emerg`, `poupança`.
- **Renda** — contém `salário`, `aluguel apart`, `renda`, `pró-labore`, `bônus`, `freela`. Nomes com `imposto`, `tarifa`, `multa` ou `juros` são testados antes e continuam como saída, para "Imposto de renda" não virar receita.
- **Custo de vida** — todo o resto, dividido em Transporte, Moradia, Cartão de crédito, Saúde e cuidados, Dívidas e impostos, Assinaturas e telecom, Pessoal e lazer, ou Outros.

As regras ficam em `CATEGORIAS`, `RE_RENDA`, `RE_APORTE` e `RE_SAIDA_FIXA`, no
topo do `<script>`. Os padrões usam `\b` onde o pedaço pode aparecer dentro de
outra palavra (`\bposto\b` não casa com "imposto"; `\bcasa\b` não casa com "casal").

## Conferência dos totais

O painel soma as linhas e compara com os totais digitados na planilha. Quando
divergem, aparece um aviso no topo dizendo quais. Hoje: o TOTAL dos
investimentos está R$ 200,00 abaixo da soma das contas, e o rendimento R$ 8,60
abaixo — os totais foram digitados à mão e não acompanharam a edição das linhas.
**O painel usa sempre a soma das linhas.**

## Atualizando pelo CSV

No Google Sheets, com a aba **Contas Fixas** aberta: *Arquivo → Fazer download →
CSV*; repita com a aba **Investimentos**. Clique em **Atualizar com CSV** e
escolha os dois arquivos, ou arraste-os para a página.

O leitor não depende de posições fixas:

- Procura blocos pelos títulos `Cartão` e qualquer `Dia <número>`; lê pares de
  nome e valor nas duas colunas seguintes até a segunda linha vazia. Dá para
  incluir, tirar e reordenar linhas.
- As linhas `Receita` e `Despesa` no fim de cada bloco são lidas só para conferência.
- Em Investimentos, procura o cabeçalho `CONTA` e lê `MODALIDADE`, `VALOR` e
  `RENDIMENTO` à direita; o objetivo é o título acima do cabeçalho. A linha
  `TOTAL` também entra só como conferência.
- Separador (`;`, `,` ou tabulação) e formato numérico (`R$ 1.234,56`, `1234.56`)
  são detectados automaticamente.

Enviar só o CSV de Investimentos atualiza esse cartão e mantém as contas fixas
embutidas. **Voltar à planilha original** restaura tudo.

## Detalhes de implementação

- Gráfico de barras em SVG puro; barras horizontais em HTML/CSS; nenhuma biblioteca.
- Tema claro e escuro por tokens CSS, seguindo o sistema ou o atributo
  `data-theme`; os gráficos são redesenhados quando o tema muda.
- Paleta validada para daltonismo e contraste — renda `#2a78d6`, custo de vida
  `#eb6834`, aportes `#1baf7a` no claro; `#3987e5`, `#d95926`, `#199e70` no escuro.
- Os dados da planilha ficam na constante `PLANILHA`, no topo do `<script>`,
  prontos para edição manual.
