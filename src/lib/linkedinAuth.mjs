const AUTHORIZATION_URL = 'https://www.linkedin.com/oauth/v2/authorization';
const ACCESS_TOKEN_URL = 'https://www.linkedin.com/oauth/v2/accessToken';

// Escopos mínimos: publicar posts + identificar o usuário autenticado.
export const DEFAULT_SCOPES = ['openid', 'profile', 'w_member_social'];

export function buildAuthorizationUrl({ clientId, redirectUri, scopes = DEFAULT_SCOPES, state }) {
  const url = new URL(AUTHORIZATION_URL);
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('client_id', clientId);
  url.searchParams.set('redirect_uri', redirectUri);
  url.searchParams.set('scope', scopes.join(' '));
  url.searchParams.set('state', state);
  return url.toString();
}

async function postForm(url, params) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(params).toString(),
  });
  const body = await res.json();
  if (!res.ok) {
    throw new Error(`LinkedIn OAuth error (${res.status}): ${JSON.stringify(body)}`);
  }
  return body;
}

export async function exchangeCodeForToken({ code, clientId, clientSecret, redirectUri }) {
  return postForm(ACCESS_TOKEN_URL, {
    grant_type: 'authorization_code',
    code,
    redirect_uri: redirectUri,
    client_id: clientId,
    client_secret: clientSecret,
  });
}

export async function refreshAccessToken({ refreshToken, clientId, clientSecret }) {
  return postForm(ACCESS_TOKEN_URL, {
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    client_id: clientId,
    client_secret: clientSecret,
  });
}
