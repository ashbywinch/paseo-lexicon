import { mkdtempSync, mkdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { isRepository, repoName, tagRepo } from "./tag";

const scratch: string[] = [];

function repoWith(dirName: string, marker: ".git" | ".lexicon"): string {
  const root = mkdtempSync(join(tmpdir(), "lexicon-"));
  const repo = join(root, dirName);
  mkdirSync(repo);
  mkdirSync(join(repo, marker), { recursive: true });
  scratch.push(root);
  return repo;
}

afterEach(() => {
  for (const dir of scratch.splice(0))
    rmSync(dir, { recursive: true, force: true });
  vi.restoreAllMocks();
});

describe("repoName", () => {
  it("strips the worktree hash prefix", () => {
    expect(repoName("/home/me/.paseo/worktrees/19odnq62-wild-falcon")).toBe(
      "wild-falcon",
    );
  });

  it("keeps a plain directory name", () => {
    expect(repoName("/home/me/Documents/code/houses")).toBe("houses");
  });

  it("falls back when the path is empty", () => {
    expect(repoName("/")).toBe("unknown");
  });
});

describe("isRepository", () => {
  it("accepts a checkout", () => {
    expect(isRepository(repoWith("houses", ".git"))).toBe(true);
  });

  it("accepts a directory carrying only a lexicon", () => {
    expect(isRepository(repoWith("docs", ".lexicon"))).toBe(true);
  });

  it("rejects a scratch directory", () => {
    const root = mkdtempSync(join(tmpdir(), "lexicon-"));
    scratch.push(root);
    expect(isRepository(root)).toBe(false);
  });
});

describe("tagRepo", () => {
  it("sends the repository name and path", async () => {
    const repo = repoWith("houses", ".git");
    const calls: Array<{ url: string; body: string }> = [];
    vi.stubGlobal(
      "fetch",
      async (url: string, init: { body: URLSearchParams }) => {
        calls.push({ url, body: init.body.toString() });
        return { ok: true, status: 200 };
      },
    );

    await expect(tagRepo(repo)).resolves.toBe(true);
    expect(calls).toHaveLength(1);
    expect(calls[0].url).toBe("http://127.0.0.1:9123/_tag");
    expect(new URLSearchParams(calls[0].body).get("repo")).toBe("houses");
    expect(new URLSearchParams(calls[0].body).get("path")).toBe(repo);
  });

  it("does not call the shim for a directory that is not a checkout", async () => {
    const root = mkdtempSync(join(tmpdir(), "lexicon-"));
    scratch.push(root);
    const fetchSpy = vi.fn();
    vi.stubGlobal("fetch", fetchSpy);

    await expect(tagRepo(root)).resolves.toBe(false);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("reports failure without throwing when the shim is down", async () => {
    const repo = repoWith("houses", ".git");
    vi.stubGlobal("fetch", async () => {
      throw new Error("ECONNREFUSED");
    });
    vi.spyOn(console, "error").mockImplementation(() => {});

    await expect(tagRepo(repo)).resolves.toBe(false);
  });
});
