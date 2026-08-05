import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { db } from './db.js';

export async function migrate(): Promise<void> {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const sql = await readFile(path.resolve(here, '../db/migrations/001_init.sql'), 'utf8');
  await db.query(sql);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  migrate().then(() => db.end()).catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
