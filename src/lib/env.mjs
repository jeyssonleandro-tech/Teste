import { readFileSync, existsSync } from 'node:fs';

// Carrega .env manualmente (sem dependência externa) só para uso local.
// Em CI (GitHub Actions), as variáveis já vêm do ambiente via `env:` no workflow.
export function loadLocalEnv() {
  if (!existsSync('.env')) return;
  const content = readFileSync('.env', 'utf8');
  for (const line of content.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (!(key in process.env)) process.env[key] = value;
  }
}

export function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Variável de ambiente obrigatória ausente: ${name}`);
  }
  return value;
}
