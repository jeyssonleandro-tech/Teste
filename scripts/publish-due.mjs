import { loadLocalEnv, requireEnv } from '../src/lib/env.mjs';
import { createTextPost } from '../src/lib/linkedinApi.mjs';
import { listPosts, savePost, STATUS } from '../src/lib/queue.mjs';

loadLocalEnv();

const accessToken = requireEnv('LINKEDIN_ACCESS_TOKEN');
const personUrn = requireEnv('LINKEDIN_PERSON_URN');

const now = Date.now();
const due = listPosts().filter(({ post }) => {
  if (post.status !== STATUS.APPROVED) return false;
  if (!post.scheduledAt) return false; // sem data definida, não publica sozinho
  return new Date(post.scheduledAt).getTime() <= now;
});

if (due.length === 0) {
  console.log('Nenhum post aprovado e no horário para publicar agora.');
  process.exit(0);
}

for (const { post } of due) {
  try {
    const { postId } = await createTextPost({ accessToken, personUrn, text: post.text });
    post.status = STATUS.PUBLISHED;
    post.publishedAt = new Date().toISOString();
    post.linkedinPostId = postId;
    savePost(post);
    console.log(`Publicado: ${post.id} -> ${postId}`);
  } catch (err) {
    console.error(`Falha ao publicar ${post.id}:`, err.message);
    process.exitCode = 1;
  }
}
