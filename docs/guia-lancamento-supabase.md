# Guia — lançar dados direto no Supabase

Guia de operação para o supervisor. Não exige programação.

## Parte 1 — Montagem inicial (uma vez só)

1. Abra o projeto no [Supabase](https://supabase.com/dashboard).
2. Menu lateral → **SQL Editor** → **New query**.
3. Copie o conteúdo de `supabase/01_schema.sql`, cole e clique em **Run**.
   Deve aparecer "Success. No rows returned".
4. Repita com `supabase/02_rls.sql` (cria as regras de acesso).
5. Opcional: repita com `supabase/03_cadastro_inicial.sql` para já criar as
   4 unidades e a lista de parâmetros. **Ajuste os nomes antes de rodar.**

### Conferindo se as regras de acesso ficaram certas

- **Table Editor** → cada tabela deve mostrar o aviso de *RLS enabled*.
- **Authentication → Policies** → duas policies por tabela: uma de leitura
  (`anon, authenticated`) e uma de escrita (só `authenticated`).

Se estiver assim, a chave pública que o dashboard usa consegue **ler** os
dados e não consegue alterar nada.

## Parte 2 — Cadastro das unidades e parâmetros (pela tela)

Se você preferiu não rodar o `03_cadastro_inicial.sql`:

1. **Table Editor** → tabela `unidades` → **Insert** → **Insert row**.
2. Preencha:
   - `nome`: ETE Industrial
   - `tipo`: ETE Industrial
   - `localizacao`: onde fica
   - `ativo`: deixe marcado
   - `id`, `criado_em`: **não preencha**, o sistema preenche sozinho.
3. Salve e repita para ETE Sanitária, ETA e Represa.
4. Faça o mesmo na tabela `parametros`, uma linha por indicador
   (DQO, pH, Turbidez, Vazão de captação...), preenchendo `nome`,
   `unidade_medida` (mg/L, m3/h, NTU) e `ordem` (10, 20, 30... define a
   ordem em que aparecem no dashboard).

Um indicador novo no futuro = uma linha nova aqui. Nada mais muda.

## Parte 3 — Rotina semanal (o que você repete)

1. **Table Editor** → tabela `leituras_semanais` → **Insert row**.
2. Preencha:

   | Campo | O que colocar |
   |---|---|
   | `unidade_id` | escolha pelo nome no seletor (ex.: *ETA*) |
   | `parametro_id` | escolha pelo nome no seletor (ex.: *Turbidez*) |
   | `semana` | a **segunda-feira** da semana de referência |
   | `valor` | o número medido (use ponto decimal: `6.9`) |
   | `observacao` | opcional, só se houver algo a registrar |

3. Salve. Repita uma linha para cada parâmetro medido na semana.

### Regras importantes da rotina

- **Sempre a mesma data de segunda-feira** para todos os lançamentos da
  mesma semana. É o que agrupa os dados no dashboard.
- Não existe linha repetida: a mesma unidade + mesmo parâmetro + mesma
  semana só pode ser lançada uma vez. Se errar o valor, **edite a linha
  existente** em vez de criar outra (clique na célula e altere).
- **Nunca escreva nome, CPF, e-mail ou telefone de pessoas** nos campos de
  texto (`observacao`, `descricao`). O dashboard é compartilhado com
  fornecedores — dado pessoal ali vira exposição desnecessária sob a LGPD.

### Lançando vários valores de uma vez

O Table Editor aceita colar do Excel: clique em **Insert → Import data from
CSV** e envie um arquivo com as colunas `unidade_id, parametro_id, semana,
valor`. Útil quando você quiser subir várias semanas de histórico de uma vez.

## Parte 4 — Chaves do projeto

Em **Project Settings → API** existem duas chaves:

- **anon / public** — é a que vai dentro do arquivo HTML do dashboard.
  Ela é visível para quem abrir o site, e tudo bem: as regras da Parte 1
  garantem que ela só lê.
- **service_role** — chave mestra, com todos os poderes.
  **Nunca** coloque no HTML, no GitHub, nem envie por e-mail/chat.

## Corrigindo um lançamento errado

- **Valor errado**: Table Editor → clique na célula → corrija → Enter.
- **Linha lançada por engano**: selecione a linha → botão direito →
  **Delete row**.
- **Semana errada**: edite o campo `semana` da linha, não crie outra.
