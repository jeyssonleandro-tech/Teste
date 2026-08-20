# Registro — formulário de lançamento e ampliação dos parâmetros

Sessão de 20 de agosto de 2026. Continuação de
`2026-08-19-planejamento-dashboard.md`. Registro estruturado das decisões
e do que foi executado.

---

## 1. Ponto de partida

O banco estava montado e o painel funcionando com dados semanais. A pauta do
dia era o formulário de lançamento para os colaboradores, item que estava em
standby desde o planejamento.

---

## 2. Decisão: registro diário em vez de semanal

**Pergunta do supervisor:** dá para alimentar diariamente em vez de só
semanalmente?

**Resposta e decisão: sim, e a granularidade passou a ser diária.**

O princípio: guardar no menor intervalo que se coleta e agregar para cima na
exibição. Diário → semanal é uma conta; semanal → diário é impossível, o
detalhe já se perdeu. O painel continua mostrando a visão semanal para os
superiores, com a diária disponível para investigar.

### O ponto que exigiu decisão: agregar não é sempre média

Somar os dias de "volume tratado" dá o total da semana. A média diária de
pluviometria não responde "quanto choveu". A régua linimétrica é um nível,
não um acumulado — vale o último valor lido.

Cada parâmetro passou a ter uma regra própria, na coluna
`parametros.agregacao`:

| Regra | Usada em |
|---|---|
| `soma` | Volume tratado, Pluviometria, águas por produto, produção |
| `ultimo` | Régua linimétrica, análises laboratoriais da ETE Sanitária, Acidez Reator |
| `media` | Concentrações e taxas — DQO, pH, vazões, turbidez, cloro |

---

## 3. Decisão: acesso por login individual

Três opções foram postas: login individual, senha única compartilhada, ou
link aberto.

**Escolhido: login individual.** É a única que impede alguém de fora inserir
dados e a única que identifica quem lançou cada medição.

Decisões de segurança que acompanharam:

- **A API não apaga dados.** Colaboradores inserem e corrigem; a exclusão só
  acontece pelo painel do Supabase, com a conta do supervisor. Se um login
  vazar, o estrago possível é dado errado, não histórico perdido.
- **`registrado_por` é dado pessoal** e fica fora das views públicas — não
  aparece no painel que os fornecedores veem. Serve para rastrear dúvidas.
- **Autocadastro deve ficar desligado** em Authentication → Providers →
  Email. Sem isso, quem descobrir o endereço do formulário cria a própria
  conta.

---

## 4. Pergunta respondida: o Supabase calcula?

Sim — e já calculava. A agregação semanal do painel é feita pelo banco, na
view; o navegador recebe o número pronto.

**Regra adotada: cálculo no banco, exibição no HTML.** Se a conta mora no
banco, ela vale para o painel, para uma exportação em Excel e para qualquer
coisa que se conecte depois. Se mora no HTML, existe só naquela página — e no
dia em que o número for para um relatório, alguém refaz a conta na mão e as
versões divergem.

Consequência prática para o cadastro: **separar o que é medido do que é
calculado**. Só o medido vira parâmetro para o operador preencher.

---

## 5. Ampliação do cadastro (CSV enviado pelo supervisor)

### O problema que a lista revelou

O cadastro exigia nome de parâmetro **único no projeto inteiro**. A lista
trazia `Volume Tratado` na ETA e na ETE Industrial, e `DQO Eflu Tratado` na
ETE Sanitária e na ETE Industrial — nomes iguais, unidades diferentes, regras
de agregação diferentes. Do jeito que estava, o segundo de cada par não
entraria.

**Correção:** a unicidade passou a ser por **nome + tipo de unidade**.

### Dupla agregação sem digitação em dobro

O supervisor precisava de Volume Tratado (ETE Industrial) tanto somado quanto
em média. Em vez de criar dois parâmetros — que obrigariam a digitar o mesmo
valor duas vezes — foi criada a coluna `agregacao_extra`: um lançamento rende
duas linhas no painel, `Volume Tratado` e `Volume Tratado (média diária)`.

### Duplicidades resolvidas por reuso, não por criação

Como o supervisor optou por manter os parâmetros antigos, foram identificados
os que eram o mesmo indicador com grafia diferente:

- `Vol Tratado` (ETA) → renomeado para `Volume Tratado`
- `Volume tratado` (ETE) → renomeado para `Volume Tratado`, com a agregação extra
- `Acidez do reator` → corrigido para `Acidez Reator`, `mgHAc/L`, último valor

### Correções sobre o CSV, confirmadas pelo supervisor

| Item do CSV | Correção |
|---|---|
| DQO Eflu Tratado (ETE Ind.) com unidade `m³` | passou a `mg/L` — é concentração |
| Volume Tratado (ETE Ind.) só como média | virou soma **e** média |
| `Produção` como localização | virou uma quinta unidade |

### O grupo genérico "ETE" foi eliminado

Passaram a existir apenas **ETE Industrial** e **ETE Sanitária**. Tudo que
valia para as duas passou a ser da Industrial. A ETE Sanitária ficou com os
quatro parâmetros do CSV: DQO Eflu Bruto, DQO Eflu Tratado, Nitrogênio e
Fósforo.

### Cadastro resultante

| Unidade | Parâmetros |
|---|---|
| ETA | Volume Tratado, Vazão de tratamento, Turbidez, Cloro Semi, Água Cervejaria, Água refrigerante, Água XS, Vazão de Entrada |
| ETE Industrial | DQO Equalizado, DQO Químico, pH Equalizado, pH Químico, pH Elev. Orgânico, Acidez Reator, Volume Tratado (+ média diária), DQO Eflu Tratado |
| ETE Sanitária | DQO Eflu Bruto, DQO Eflu Tratado, Nitrogênio, Fósforo |
| Represa | Vazão de captação, Régua linimétrica, Pluviometria |
| Produção | Volume de produção |

---

## 6. Percalços do dia

| Erro | Causa | Solução |
|---|---|---|
| `42P01: relation "public.leituras_semanais" does not exist` | A migração já tinha rodado com sucesso; era a segunda execução, e a tabela já se chamava `leituras` | Diagnóstico por `information_schema.tables`; o script foi tornado repetível com um bloco `do $$` que só renomeia o que ainda não foi renomeado |

Reforço do padrão já conhecido: colar **um script por vez** no SQL Editor,
limpando o editor antes, porque ele executa tudo o que estiver na tela.

---

## 7. O que ficou pronto

| Arquivo | Conteúdo |
|---|---|
| `lancamento.html` | Formulário com login, parâmetros filtrados pela unidade, correção de lançamentos, vírgula decimal |
| `supabase/04_migracao_diaria.sql` | Semanal → diário, `registrado_por`, regras de agregação, as duas views |
| `supabase/05_parametros_v2.sql` | Unicidade por tipo, `agregacao_extra`, unidade Produção, novos parâmetros |
| `index.html` | Alternância entre visão semanal e diária |
| `docs/guia-lancamento-supabase.md` | Reescrito: criação de logins, rotina diária, regras de agregação |

### Problema encontrado no teste do painel

No modo diário, com 30 pontos no gráfico, as áreas de toque dos pontos se
sobrepunham e uma bloqueava a outra — o tooltip dos primeiros pontos ficava
inalcançável. Corrigido: o raio da área de toque acompanha o espaçamento, e
as bolinhas somem quando a série fica densa, deixando só a linha.

### Limitação registrada

O ambiente onde o Claude roda tem saída de rede restrita e não alcança
`supabase.co`. Não é questão de permissão: mesmo com credenciais, as chamadas
não sairiam. O fluxo de trabalho continua sendo o Claude gerar o SQL e o
supervisor colar no SQL Editor — o que, para dezenas de parâmetros, é o mesmo
esforço que para um.

---

## 8. Em aberto

| Item | Esperando |
|---|---|
| Índice de Água (L/L, ETA, calculado) | Parâmetros complementares a levantar, e então a fórmula |
| Publicação no GitHub Pages | Decisão: branch de trabalho ou `main` |
| Sinalização de fora de faixa | Limites de conformidade por parâmetro |
| Troca de senha pelo próprio colaborador | Decisão sobre a necessidade |
| Vínculo com a planta baixa | — |

### Nota sobre o Índice de Água

É uma razão, e razão não se agrega por média: a média dos índices diários da
semana não é o índice da semana. O correto é somar o numerador do período e
dividir pela soma do denominador. Quando a fórmula for definida, implementar
assim.
