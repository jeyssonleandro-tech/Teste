# Guia — lançamento e operação

Guia de operação. Não exige programação.

- **Colaboradores** → só precisam da [Parte 4](#parte-4--rotina-de-lançamento-colaboradores).
- **Supervisor** → Partes 1 a 3 e 5.

---

## Parte 1 — Montagem inicial (uma vez só)

No painel do [Supabase](https://supabase.com/dashboard) → **SQL Editor** →
**New query**. Cole **um script por vez**, limpando o editor entre eles
(Ctrl+A → apagar), porque ele executa tudo o que estiver na tela.

| Ordem | Arquivo | O que faz |
|---|---|---|
| 1 | `supabase/01_schema.sql` | Cria as tabelas e a view |
| 2 | `supabase/02_rls.sql` | Regras de acesso |
| 3 | `supabase/03_cadastro_inicial.sql` | Cadastra unidades e parâmetros |
| 4 | `supabase/04_migracao_diaria.sql` | Muda para lançamento diário e cria o login |

Cada um deve responder "Success".

### Conferindo as regras de acesso

- **Table Editor** → cada tabela mostra *RLS enabled*.
- **Authentication → Policies** → leitura para `anon`; escrita só para
  `authenticated`.

Resultado: a chave pública que o painel usa **lê e não grava**.

---

## Parte 2 — Criando os acessos dos colaboradores

Cada pessoa que vai lançar precisa de um login. Você cria, não há
autocadastro.

1. **Authentication** → **Users** → **Add user** → **Create new user**
2. Preencha e-mail e uma senha inicial
3. Marque **Auto Confirm User** — sem isso a pessoa não consegue entrar
4. **Create user**
5. Repasse o e-mail e a senha ao colaborador

Para **remover** um acesso (desligamento, troca de função): mesma tela,
selecione o usuário → **Delete user**. A partir daí ele não grava mais nada,
e os lançamentos que já fez permanecem.

> **Recomendação de segurança:** desative o autocadastro em
> **Authentication → Providers → Email**, deixando *Enable Sign Up*
> desligado. Sem isso, qualquer pessoa com o endereço do formulário poderia
> criar a própria conta e lançar dados.

---

## Parte 3 — Cadastro de unidades e parâmetros

Se você não rodou o `03_cadastro_inicial.sql`, ou quer acrescentar algo:

1. **Table Editor** → tabela `unidades` → **Insert** → **Insert row**
2. Preencha `nome`, `tipo` e deixe `ativo` marcado.
   `id` e `criado_em` o sistema preenche sozinho.
3. Faça o mesmo em `parametros`, preenchendo:
   - `nome` — como aparece no formulário e no painel
   - `unidade_medida` — mg/L, m3/h, NTU…
   - `aplica_a_tipo` — **define em quais unidades o parâmetro aparece**
   - `ordem` — 10, 20, 30… controla a ordem de exibição
   - `agregacao` — `media`, `soma` ou `ultimo` (ver Parte 5)

### Como o `aplica_a_tipo` funciona

O formulário mostra um parâmetro quando o **tipo da unidade** e o
`aplica_a_tipo` combinam pelo início do texto:

| `aplica_a_tipo` | Aparece em |
|---|---|
| `ETE` | ETE Industrial **e** ETE Sanitária |
| `ETE Industrial` | só na ETE Industrial |
| `ETA` | só na ETA |
| `Represa` | só na Represa |

Ou seja: use `ETE` para o que é comum às duas, e o nome completo para o que é
exclusivo de uma.

---

## Parte 4 — Rotina de lançamento (colaboradores)

1. Abra o formulário (`lancamento.html`)
2. Entre com o e-mail e a senha que o supervisor forneceu
3. Escolha a **unidade** e confira a **data** (vem preenchida com hoje)
4. Preencha os valores medidos — **use vírgula para decimal**: `7,2`
5. Deixe em branco o que não foi medido; só o que tem valor é gravado
6. **Salvar lançamento**

O painel reflete o lançamento na hora — basta recarregar a página.

### Regras da rotina

- **Corrigir um valor:** abra a mesma unidade e a mesma data, ajuste o número
  e salve de novo. O sistema substitui o valor anterior; ele avisa quais
  campos já têm lançamento.
- **Lançar um dia anterior:** troque a data. Datas futuras são bloqueadas.
- **Nunca escreva nome, CPF, telefone ou e-mail de pessoas** na observação. O
  painel é compartilhado com fornecedores — dado pessoal ali vira exposição
  desnecessária sob a LGPD.
- O sistema registra quem lançou cada medição. Isso serve para rastrear
  dúvidas e **não aparece no painel**.

### Se aparecer "Sua sessão expirou"

Normal após um tempo sem uso. Entre de novo e refaça o lançamento.

---

## Parte 5 — Como os dias viram semanas

O painel tem duas visões. Na **diária**, cada dia é um ponto. Na **semanal**,
o banco junta os dias conforme a natureza de cada indicador:

| Regra | Usada em | Por quê |
|---|---|---|
| `soma` | Volume tratado, Vol Tratado, Pluviometria | O total da semana é a soma dos dias; a média diária de chuva não responde "quanto choveu" |
| `ultimo` | Régua linimétrica | É um nível, não um acumulado: vale o último valor lido |
| `media` | DQO, pH, Acidez, Vazões, Turbidez, Cloro | São concentrações e taxas; a média representa o período |

Para mudar a regra de um parâmetro: **Table Editor** → `parametros` → coluna
`agregacao` → `media`, `soma` ou `ultimo`.

A semana começa na **segunda-feira** e é identificada por essa data.

---

## Parte 6 — Chaves do projeto

Em **Project Settings → API**:

- **anon / public** — vai dentro dos arquivos HTML. É visível para quem abrir
  a página, e tudo bem: as regras da Parte 1 garantem que ela só lê.
- **service_role** — chave mestra. **Nunca** no HTML, no GitHub, ou por
  e-mail/chat.

---

## Apagando um lançamento

Por segurança, o formulário e a API **não apagam** — evita que um login
comprometido destrua o histórico. Para excluir de fato: **Table Editor** →
`leituras` → selecione a linha → **Delete row**, com a sua conta de
supervisor.
