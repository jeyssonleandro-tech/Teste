import { readdirSync, readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

export const QUEUE_DIR = 'content/queue';

export const STATUS = {
  DRAFT: 'draft',
  PENDING_REVIEW: 'pending_review',
  APPROVED: 'approved',
  PUBLISHED: 'published',
  REJECTED: 'rejected',
};

export function ensureQueueDir() {
  if (!existsSync(QUEUE_DIR)) mkdirSync(QUEUE_DIR, { recursive: true });
}

export function listPosts() {
  ensureQueueDir();
  return readdirSync(QUEUE_DIR)
    .filter((f) => f.endsWith('.json'))
    .map((f) => ({ file: join(QUEUE_DIR, f), post: JSON.parse(readFileSync(join(QUEUE_DIR, f), 'utf8')) }));
}

export function savePost(post) {
  ensureQueueDir();
  const file = join(QUEUE_DIR, `${post.id}.json`);
  writeFileSync(file, JSON.stringify(post, null, 2) + '\n');
  return file;
}

export function newPost({ topic, text, scheduledAt }) {
  const id = new Date().toISOString().replace(/[:.]/g, '-') + '-' + Math.random().toString(36).slice(2, 8);
  return {
    id,
    topic: topic ?? null,
    text,
    status: STATUS.PENDING_REVIEW,
    scheduledAt: scheduledAt ?? null,
    createdAt: new Date().toISOString(),
    publishedAt: null,
    linkedinPostId: null,
    metrics: null,
  };
}
