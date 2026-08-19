const API_BASE = 'https://api.linkedin.com';
const REST_VERSION = '202405'; // LinkedIn exige um header de versão nas rotas /rest/*

async function request(path, { method = 'GET', accessToken, body, extraHeaders = {} } = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      'X-Restli-Protocol-Version': '2.0.0',
      'LinkedIn-Version': REST_VERSION,
      ...extraHeaders,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await res.text();
  const data = text ? JSON.parse(text) : null;

  if (!res.ok) {
    throw new Error(`LinkedIn API error (${res.status}) em ${path}: ${JSON.stringify(data)}`);
  }
  return { data, headers: res.headers };
}

// Retorna o "sub" (id da pessoa) via OpenID Connect userinfo.
export async function getUserInfo(accessToken) {
  const { data } = await request('/v2/userinfo', { accessToken });
  return data; // { sub, name, email, ... }
}

// Cria um post de texto simples no perfil pessoal.
// personUrn no formato: urn:li:person:XXXXXXXX
export async function createTextPost({ accessToken, personUrn, text, visibility = 'PUBLIC' }) {
  const { data, headers } = await request('/rest/posts', {
    method: 'POST',
    accessToken,
    body: {
      author: personUrn,
      commentary: text,
      visibility,
      distribution: {
        feedDistribution: 'MAIN_FEED',
        targetEntities: [],
        thirdPartyDistributionChannels: [],
      },
      lifecycleState: 'PUBLISHED',
      isReshareDisabledByAuthor: false,
    },
  });
  // LinkedIn retorna o id do post no header x-restli-id (não no corpo)
  const postId = headers.get('x-restli-id');
  return { postId, data };
}

// Métricas por post são só o que a API pública libera (bem limitado para perfil pessoal).
// Usa o "Social Actions" endpoint para likes/comments quando disponível.
export async function getSocialActionsSummary({ accessToken, postUrn }) {
  const encoded = encodeURIComponent(postUrn);
  const { data } = await request(`/v2/socialActions/${encoded}`, { accessToken });
  return data;
}
