# Fila de conteúdo

Cada arquivo em `queue/` é um post em algum estágio do ciclo de vida:

```json
{
  "id": "2026-08-19T18-30-00-000Z-ab12cd",
  "topic": "tema opcional, livre",
  "text": "texto que será publicado no LinkedIn",
  "status": "pending_review",
  "scheduledAt": "2026-08-25T09:00:00-03:00",
  "createdAt": "2026-08-19T18:30:00.000Z",
  "publishedAt": null,
  "linkedinPostId": null,
  "metrics": null
}
```

## Estados (`status`)

- `draft` — rascunho inicial, ainda sendo lapidado.
- `pending_review` — pronto para você revisar o texto e a data.
- `approved` — revisado; será publicado automaticamente quando `scheduledAt`
  chegar (workflow roda a cada hora). Sem `scheduledAt`, nunca publica
  sozinho.
- `published` — já publicado; `linkedinPostId` e `publishedAt` preenchidos.
- `rejected` — descartado, mantido apenas para histórico.

## Fluxo recomendado

1. `npm run queue:new -- "texto" "2026-08-25T09:00:00-03:00" "tema"` cria o
   rascunho.
2. Revise o texto e a data (horário de São Paulo, `-03:00`).
3. Mude `status` para `approved` e faça commit/push (ou PR, se quiser uma
   segunda revisão antes do merge).
4. O workflow de publicação faz o resto e atualiza o arquivo.
