import { loadLocalEnv, requireEnv } from '../src/lib/env.mjs';
import { getSocialActionsSummary } from '../src/lib/linkedinApi.mjs';
import { listPosts, savePost, STATUS } from '../src/lib/queue.mjs';

loadLocalEnv();

const accessToken = requireEnv('LINKEDIN_ACCESS_TOKEN');

// AVISO: a API pública do LinkedIn não expõe impressões/alcance para posts de
// perfil pessoal (isso fica no Marketing Developer Platform, que exige parceria
// aprovada pelo LinkedIn). Aqui coletamos só o que o endpoint social actions libera
// (likes/comments), quando disponível para o token atual.
const published = listPosts().filter(({ post }) => post.status === STATUS.PUBLISHED && post.linkedinPostId);

for (const { post } of published) {
  try {
    const summary = await getSocialActionsSummary({ accessToken, postUrn: post.linkedinPostId });
    post.metrics = { collectedAt: new Date().toISOString(), ...summary };
    savePost(post);
    console.log(`Métricas atualizadas: ${post.id}`);
  } catch (err) {
    console.error(`Sem métricas para ${post.id}: ${err.message}`);
  }
}
