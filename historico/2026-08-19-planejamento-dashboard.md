# Registro do projeto — Dashboard das Estações de Tratamento

Conversa entre o supervisor de estação de tratamento e o Claude Code,
em 19 e 20 de agosto de 2026. Este documento é o registro estruturado do
que foi decidido e executado — não a transcrição literal.

---

## 1. O pedido original

Criar um dashboard, atualizado semanalmente, com os dados operacionais das
estações de tratamento, para responder rapidamente a superiores e a
fornecedores. Hoje os dados vivem em planilha.

Restrições colocadas desde o início:

- A empresa tem limitações de acesso por questões de **LGPD** — nada podia ser
  executado antes de um planejamento aprovado.
- O frontend ficaria no **GitHub**; o armazenamento, no **Supabase**.
- O resultado precisa ser um arquivo **HTML** visualizável.

---

## 2. Análise de LGPD

Separação feita logo no início:

| Tipo de dado | Exemplos | Cai na LGPD? |
|---|---|---|
| Operacional/técnico | vazão, DQO, pH, turbidez, volume tratado | Não |
| Pessoal | nome do operador, contato de fornecedor, CPF | **Sim** |

**Decisão:** o painel contém apenas dados técnicos. Campos de texto livre
(`observacao`, `descricao`) trazem aviso explícito para nunca receberem nome,
CPF, e-mail ou telefone de pessoas.

Pendência que coube ao usuário validar internamente e foi confirmada:
autorização da TI/compliance para usar o Supabase (SaaS externo) e para
compartilhar o link do painel.

---

## 3. Decisões de arquitetura

### 3.1 Uma base só, não uma por tipo de unidade

Pergunta levantada: ETE Industrial, ETE Sanitária, ETA e Represa medem
indicadores diferentes — bases separadas?

**Decisão: uma base (um projeto Supabase) só.** A separação entre os tipos
acontece dentro das tabelas. Bases separadas obrigariam o painel a consultar
quatro lugares diferentes.

### 3.2 Três tabelas, não uma coluna por indicador

O caminho ingênuo — uma coluna para cada indicador possível — geraria uma
tabela cheia de células vazias (a ETA nunca tem "acidez do reator") e exigiria
alterar a estrutura sempre que surgisse um indicador novo.

**Decisão: modelo em três tabelas.**

- `unidades` — cadastro de cada estação/represa
- `parametros` — catálogo de indicadores (nome, unidade de medida, ordem)
- `leituras_semanais` — uma linha por unidade + parâmetro + semana

Consequência prática: **indicador novo = uma linha nova em `parametros`**,
sem mexer em estrutura. Cada unidade só gera linhas dos parâmetros que fazem
sentido para ela.

Existe ainda `ocorrencias`, para eventos fora do padrão (manutenção, parada,
não-conformidade).

### 3.3 Uma view como camada pública

O HTML consulta a view `vw_dashboard`, nunca as tabelas cruas. Serve como
"vitrine": se um dia surgir uma coluna que não deve ser pública, basta não
incluí-la na view.

### 3.4 Rota de entrada dos dados

Duas rotas foram apresentadas:

- **Rota A** — a planilha passa pelo Claude, que transforma e insere.
- **Rota B** — lançamento direto no Supabase.

**Decisão do usuário: Rota B** para dados reais, com um guia de operação
escrito. Rota A ficaria só para protótipo com dados fictícios. Motivo: menor
superfície de risco sob a LGPD, já que o dado não passa por um terceiro.

### 3.5 Controle de acesso (RLS)

- Chave `anon/public`, embutida no HTML → **somente leitura**.
- Usuário autenticado (o supervisor) → leitura e escrita.
- Chave `service_role` → nunca vai para o HTML nem para o GitHub.

Na prática: nenhuma policy de INSERT/UPDATE/DELETE existe para `anon`, então
essas operações ficam bloqueadas por padrão mesmo que alguém copie a chave do
código-fonte da página.

### 3.6 Sem juízo de valor nos números

A variação semanal aparece em cinza neutro, com seta, **sem cor de "bom" ou
"ruim"**. Motivo: sem limites de conformidade definidos, colorir seria emitir
um juízo que o dado não sustenta — DQO subindo é ruim, volume tratado subindo
é bom. Fica pendente até o usuário fornecer as faixas aceitáveis.

### 3.7 Escala própria por indicador

Os indicadores têm ordens de grandeza muito diferentes (pH ≈ 7, volume ≈
12.000 m³). Em vez de um gráfico com dois eixos — que distorce a leitura —
cada parâmetro tem seu próprio mini-gráfico com escala própria.

---

## 4. Cadastro definido

### Unidades

| nome | tipo |
|---|---|
| ETE Industrial | ETE Industrial |
| ETE Sanitária | ETE Sanitária |
| ETA | ETA |
| Represa | Represa |

O campo `localizacao` foi **removido do cadastro e do painel** a pedido do
usuário — a coluna continua existindo na tabela, vazia, reservada para o
futuro vínculo com a planta baixa das unidades.

### Parâmetros

| Unidade | Parâmetro | Medida |
|---|---|---|
| ETE | DQO Equalizado | mg/L |
| ETE | DQO Químico | mg/L |
| ETE | pH Equalizado | - |
| ETE | pH Químico | - |
| ETE | pH Elev. Orgânico | - |
| ETE Industrial | Acidez do reator | mg/L |
| ETE | Volume tratado | m³ |
| ETA | Vol Tratado | m³ |
| ETA | Vazão de tratamento | m³/h |
| ETA | Turbidez | NTU |
| ETA | Cloro Semi | ppm |
| Represa | Vazão de captação | m³/h |
| Represa | Régua linimétrica | m |
| Represa | Pluviometria | mm |

---

## 5. Percalços encontrados e como foram resolvidos

| Erro | Causa | Solução |
|---|---|---|
| `42601: erro de sintaxe próximo a "Fases"` | O texto da resposta do chat foi colado no SQL Editor, em vez do conteúdo do arquivo | Passar o SQL em bloco de código, um script por vez |
| Script de parâmetros não rodava | Faltava a linha `insert into public.parametros (...) values` e uma vírgula entre duas linhas | Corrigido no arquivo do repositório |
| Tipos inconsistentes (`' Industrial'`, `'Sanitária'`) | Espaço à frente e nome sem o prefixo | Padronizado para `ETE Industrial` / `ETE Sanitária`, casando com o `aplica_a_tipo` |
| `42P16: não é possível remover colunas da visualização` | `create or replace view` só acrescenta colunas, nunca remove | Trocado por `drop view` + `create view` |

Vale registrar o padrão: colar no SQL Editor sempre **um script por vez**, com
o editor limpo antes (Ctrl+A → apagar), porque ele executa tudo o que estiver
na tela.

---

## 6. O que ficou pronto

| Arquivo | Conteúdo |
|---|---|
| `supabase/01_schema.sql` | Tabelas e a view `vw_dashboard` |
| `supabase/02_rls.sql` | Regras de acesso |
| `supabase/03_cadastro_inicial.sql` | Cadastro das unidades e parâmetros |
| `docs/guia-lancamento-supabase.md` | Guia de operação da rotina semanal |
| `index.html` | O painel |

O painel foi validado com dados simulados, em três cenários — com dados, sem
dados e com falha de autenticação — em tema claro e escuro, e em viewport de
celular (390×844): sem erros de console, sem rolagem lateral, e a tabela de
histórico rolando dentro da própria caixa. O usuário confirmou que a conexão
real com o banco funciona.

Recursos do painel: cartões por parâmetro com último valor e variação
semanal, gráfico de tendência individual, filtros por unidade e por período,
tabela de histórico sob demanda, tema claro/escuro, e mensagens próprias para
os estados de vazio e de erro.

---

## 7. Em aberto

| Item | Situação |
|---|---|
| Publicação no GitHub Pages (acesso mobile) | Aguardando decisão: publicar da branch de trabalho ou da `main` |
| Sinalização de fora de faixa | Aguardando os limites de conformidade de cada parâmetro |
| Formulário HTML de lançamento | Standby — substituiria o Table Editor na rotina semanal |
| Vínculo com a planta baixa | Standby — campo `localizacao` já reservado na tabela |

O layout já é responsivo; o que falta para o acesso via celular é apenas a
publicação, já que um arquivo local não abre em outro aparelho.
