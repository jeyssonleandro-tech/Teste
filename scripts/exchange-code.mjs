import { loadLocalEnv, requireEnv } from '../src/lib/env.mjs';
import { exchangeCodeForToken } from '../src/lib/linkedinAuth.mjs';

loadLocalEnv();

const code = process.argv[2];
if (!code) {
  console.error('Uso: npm run auth:exchange -- "<code>"');
  process.exit(1);
}

const clientId = requireEnv('LINKEDIN_CLIENT_ID');
const clientSecret = requireEnv('LINKEDIN_CLIENT_SECRET');
const redirectUri = requireEnv('LINKEDIN_REDIRECT_URI');

const tokens = await exchangeCodeForToken({ code, clientId, clientSecret, redirectUri });

console.log('\nTokens recebidos. Guarde-os como GitHub Secrets (nunca commite no repositório):\n');
console.log(`LINKEDIN_ACCESS_TOKEN=${tokens.access_token}`);
if (tokens.refresh_token) console.log(`LINKEDIN_REFRESH_TOKEN=${tokens.refresh_token}`);
console.log(`\nExpira em ${tokens.expires_in} segundos (~${Math.round(tokens.expires_in / 86400)} dias).`);
console.log('\nPróximo passo: rode "npm run auth:profile" para descobrir seu LINKEDIN_PERSON_URN.\n');
