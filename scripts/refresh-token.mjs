import { loadLocalEnv, requireEnv } from '../src/lib/env.mjs';
import { refreshAccessToken } from '../src/lib/linkedinAuth.mjs';

loadLocalEnv();

const clientId = requireEnv('LINKEDIN_CLIENT_ID');
const clientSecret = requireEnv('LINKEDIN_CLIENT_SECRET');
const refreshToken = requireEnv('LINKEDIN_REFRESH_TOKEN');

const tokens = await refreshAccessToken({ refreshToken, clientId, clientSecret });

console.log(`LINKEDIN_ACCESS_TOKEN=${tokens.access_token}`);
if (tokens.refresh_token) console.log(`LINKEDIN_REFRESH_TOKEN=${tokens.refresh_token}`);
console.log(`# expira em ~${Math.round(tokens.expires_in / 86400)} dias`);
