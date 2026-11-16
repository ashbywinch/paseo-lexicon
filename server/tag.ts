// Tagging logic, kept apart from the hook so it can be tested without a daemon.

import { existsSync } from "node:fs";
import { join } from "node:path";

export const DEFAULT_SHIM_URL = "http://127.0.0.1:9123/_tag";
const TAG_TIMEOUT_MS = 1_500;

/** Worktree directories are named `<hash>-<slug>`; the shim only needs a readable name. */
export function repoName(cwd: string): string {
  const parts = cwd.split("/").filter(Boolean);
  const last = parts[parts.length - 1] ?? "unknown";
  return last.replace(/^[a-z0-9]{7,}-/, "");
}

/** Only a real checkout is worth reporting; a scratch directory would evict the user's repository. */
export function isRepository(cwd: string): boolean {
  return existsSync(join(cwd, ".git")) || existsSync(join(cwd, ".lexicon"));
}

export async function tagRepo(
  cwd: string,
  hookSignal?: AbortSignal,
  shimUrl = DEFAULT_SHIM_URL,
): Promise<boolean> {
  if (!isRepository(cwd)) return false;
  const body = new URLSearchParams({ repo: repoName(cwd), path: cwd });
  const timeout = AbortSignal.timeout(TAG_TIMEOUT_MS);
  const signal = hookSignal ? AbortSignal.any([hookSignal, timeout]) : timeout;
  try {
    const response = await fetch(shimUrl, { method: "POST", body, signal });
    if (!response.ok) {
      console.error(`lexicon: tag rejected ${response.status} for ${cwd}`);
      return false;
    }
    return true;
  } catch (error) {
    // The shim may be stopped; dictation then falls back to the shared list, which is not worth
    // failing a turn over.
    console.error(`lexicon: tag failed for ${cwd}: ${String(error)}`);
    return false;
  }
}
