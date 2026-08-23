# Publicar o painel e liberar o acesso pelo celular

Enquanto o painel for um arquivo no seu computador, ele só funciona no seu
computador. Publicar significa dar a ele um endereço na internet — e é isso
que faz o celular funcionar, o seu e o dos outros.

---

## Antes de publicar: fechar a leitura

**Rode `supabase/06_acesso_autenticado.sql` primeiro.** Sem ele, qualquer
pessoa que descobrir o endereço vê os dados de processo da planta.

Depois desse script, a chave `anon` que está dentro do HTML serve só para
fazer login. Sem usuário e senha, o painel não mostra nada — nem que alguém
copie a chave do código-fonte da página.

Consequência: **quem só vai olhar também precisa de login.** Superiores e
fornecedores entram em Authentication → Users como qualquer colaborador; a
diferença é que eles não usam o formulário de lançamento.

---

## Passo a passo no GitHub

O painel mora no branch `main` — a linha principal do repositório. É de lá
que o site é publicado, para o endereço não mudar quando a gente estiver
mexendo em outra coisa.

1. Abra o repositório no GitHub → **Settings** (aba no topo).
2. Menu da esquerda → **Pages**.
3. Em *Build and deployment* → *Source*, escolha **Deploy from a branch**.
4. Em *Branch*, escolha **`main`** e a pasta **`/ (root)`**. Salve.
5. Espere um ou dois minutos e recarregue a página. O endereço aparece no
   topo, no formato:

   ```
   https://jeyssonleandro-tech.github.io/Teste/
   ```

   O formulário de lançamento fica em `.../Teste/lancamento.html`.

### O repositório precisa ser público

Hoje `Teste` é privado, e o GitHub Pages em repositório privado exige plano
pago. Duas saídas:

- **Tornar o repositório público** (Settings → General → Danger Zone →
  Change visibility). Com o script 06 aplicado, isso não expõe dado nenhum:
  o que fica visível é o código do painel e os scripts SQL, não as leituras.
- **Assinar o GitHub Pro.** Mesmo assim o *site* publicado continua público;
  o que muda é só o repositório continuar fechado.

Note que a chave `anon` fica visível no código em qualquer um dos casos —
isso é por projeto do Supabase, e é seguro justamente porque as regras de
RLS não deixam essa chave ler nem gravar nada.

---

## No celular

Abra o endereço no navegador e adicione à tela de início:

- **Android (Chrome):** menu ⋮ → *Adicionar à tela inicial*
- **iPhone (Safari):** botão de compartilhar → *Adicionar à Tela de Início*

Fica com cara de aplicativo e o login continua salvo entre as aberturas.

---

## Publicando uma alteração

Toda alteração é feita num branch de trabalho e depois levada para o `main`.
Quando o `main` recebe a mudança, o GitHub republica o site sozinho em um
ou dois minutos — não há botão de publicar.

Se o site parecer não ter mudado, é cache do navegador: recarregue segurando
Shift (computador) ou feche e reabra a aba (celular).
