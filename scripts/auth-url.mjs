import { loadLocalEnv, requireEnv } from '../src/lib/env.mjs';
import { buildAuthorizationUrl } from '../src/lib/linkedinAuth.mjs';
import { randomBytes } from 'node:crypto';

loadLocalEnv();

const clientId = requireEnv('LINKEDIN_CLIENT_ID');
const redirectUri = requireEnv('LINKEDIN_REDIRECT_URI');
const state = randomBytes(8).toString('hex');

const url = buildAuthorizationUrl({ clientId, redirectUri, state });

console.log('\n1. Abra esta URL no SEU navegador e faça login no LinkedIn:\n');
console.log(url);
console.log('\n2. Após autorizar, você será redirecionado para uma URL como:');
console.log(`   ${redirectUri}?code=AQT...&state=${state}`);
console.log('\n3. Copie o valor de "code" da barra de endereço e rode:');
console.log('   npm run auth:exchange -- "<code>"\n');
