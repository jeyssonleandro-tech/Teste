import { loadLocalEnv, requireEnv } from '../src/lib/env.mjs';
import { getUserInfo } from '../src/lib/linkedinApi.mjs';

loadLocalEnv();

const accessToken = requireEnv('LINKEDIN_ACCESS_TOKEN');
const info = await getUserInfo(accessToken);

console.log('\nPerfil autenticado:', info.name ?? '(sem nome)');
console.log(`\nGuarde este valor como GitHub Secret:\nLINKEDIN_PERSON_URN=urn:li:person:${info.sub}\n`);
