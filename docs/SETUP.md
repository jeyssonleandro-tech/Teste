# Configuração do agente de conteúdo do LinkedIn

Este guia cobre o que só você pode fazer (login no LinkedIn, criar o app,
autorizar o acesso) e o que já está pronto no repositório.

## Limitações importantes da API do LinkedIn (leia antes de começar)

- **Publicar** no seu perfil pessoal é possível com o produto "Share on
  LinkedIn". Sem isso, a API rejeita a criação de posts.
- **Métricas** (impressões, alcance, cliques) de posts de perfil pessoal
  **não são expostas** pela API pública — isso fica no Marketing Developer
  Platform, que exige parceria aprovada pelo LinkedIn e é voltado
  principalmente a Company Pages. O agente coleta apenas o que o endpoint
  `socialActions` liberar (curtidas/comentários), quando disponível.
- **Refresh token automático** só funciona se o LinkedIn aprovar o recurso
  "Programmatic refresh tokens" para o seu app — nem todo app recebe isso
  por padrão. Se não vier `refresh_token` na resposta, o `access_token`
  (válido ~60 dias) vai expirar e você precisará reautorizar manualmente
  repetindo o passo 4 abaixo.
- O LinkedIn pode revisar/aprovar produtos do app com atraso (às vezes dias).

## Passo 1 — Criar o app no LinkedIn Developer Portal

1. Acesse https://www.linkedin.com/developers/apps e clique em "Create app".
2. Preencha nome do app, associe a uma "Company Page" (o LinkedIn exige uma
   página vinculada mesmo para publicar no perfil pessoal — pode ser uma
   página simples criada só para isso).
3. Na aba **Products**, solicite:
   - **Sign In with LinkedIn using OpenID Connect**
   - **Share on LinkedIn**
4. Na aba **Auth**, anote `Client ID` e `Client Secret`, e cadastre uma
   **Authorized redirect URL**. Como não temos um servidor rodando, use
   algo simples que só você acessa, por exemplo `http://localhost:3000/callback`
   (não precisa haver nada rodando nesse endereço — você só vai copiar o
   `code` da barra de endereço depois do redirect).

## Passo 2 — Configurar variáveis localmente (só na sua máquina)

```bash
cp .env.example .env
# edite .env e preencha:
# LINKEDIN_CLIENT_ID, LINKEDIN_CLIENT_SECRET, LINKEDIN_REDIRECT_URI
```

`.env` está no `.gitignore` — nunca será commitado.

## Passo 3 — Gerar a URL de autorização

```bash
npm run auth:url
```

Abra a URL impressa **no seu navegador**, faça login no LinkedIn e autorize
o app. Você será redirecionado para algo como:

```
http://localhost:3000/callback?code=AQT...&state=...
```

A página provavelmente mostrará erro de conexão (normal, não há servidor
ali) — copie o valor de `code` direto da barra de endereço do navegador.

## Passo 4 — Trocar o código por tokens

```bash
npm run auth:exchange -- "COLE_O_CODE_AQUI"
```

Isso imprime `LINKEDIN_ACCESS_TOKEN` (e `LINKEDIN_REFRESH_TOKEN`, se o app
tiver o recurso liberado).

## Passo 5 — Descobrir seu Person URN

```bash
npm run auth:profile
```

Imprime `LINKEDIN_PERSON_URN=urn:li:person:XXXXX`.

## Passo 6 — Cadastrar GitHub Secrets

No repositório: **Settings → Secrets and variables → Actions → New
repository secret**. Cadastre:

- `LINKEDIN_CLIENT_ID`
- `LINKEDIN_CLIENT_SECRET`
- `LINKEDIN_ACCESS_TOKEN`
- `LINKEDIN_REFRESH_TOKEN` (se disponível)
- `LINKEDIN_PERSON_URN`

Nunca cole esses valores em arquivos do repositório — apenas em Secrets.

## Passo 7 — Testar o fluxo ponta a ponta

1. Criar um rascunho:
   ```bash
   npm run queue:new -- "Texto do meu post de teste" "2026-08-25T09:00:00-03:00" "tema opcional"
   ```
   Isso cria um arquivo em `content/queue/` com `status: "pending_review"`.
2. Revisar o texto e a data no arquivo gerado.
3. Aprovar: edite o campo `"status"` para `"approved"` e faça commit/push
   (ou abra um PR se quiser revisão adicional antes do merge).
4. O workflow `publish-scheduled.yml` roda a cada hora e publica os posts
   `approved` cujo `scheduledAt` já passou, atualizando o status para
   `published` e commitando de volta a fila.
5. Para forçar uma execução sem esperar o cron, use **Actions → Publicar
   posts agendados no LinkedIn → Run workflow**.

## Renovando o access token quando expirar

Se você tiver `LINKEDIN_REFRESH_TOKEN`:

```bash
npm run auth:refresh
```

e atualize o secret `LINKEDIN_ACCESS_TOKEN` no GitHub com o valor impresso.

Se não tiver refresh token, repita os passos 3 e 4.
