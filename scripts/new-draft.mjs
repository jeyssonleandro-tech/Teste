import { loadLocalEnv } from '../src/lib/env.mjs';
import { newPost, savePost } from '../src/lib/queue.mjs';

loadLocalEnv();

// Uso: npm run queue:new -- "texto do post" "2026-08-25T09:00:00-03:00" "tema opcional"
const [text, scheduledAt, topic] = process.argv.slice(2);

if (!text) {
  console.error('Uso: npm run queue:new -- "texto do post" "2026-08-25T09:00:00-03:00" ["tema"]');
  console.error('scheduledAt é opcional e deve estar em horário de São Paulo (America/Sao_Paulo).');
  process.exit(1);
}

const post = newPost({ text, scheduledAt: scheduledAt ?? null, topic: topic ?? null });
const file = savePost(post);

console.log(`Rascunho criado em ${file} com status "${post.status}".`);
console.log('Para publicar, edite o arquivo e mude "status" para "approved" (após revisar o texto e a data).');
