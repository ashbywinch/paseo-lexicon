import { describe, expect, it, vi } from "vitest";
import contribute from "../index.server";

describe("contribute", () => {
  it("registers one turn hook and returns its remover", () => {
    const remove = vi.fn();
    const addHook = vi.fn((_name: string, _handler: unknown) => remove);
    const cleanup = contribute({ addHook } as never);

    expect(addHook).toHaveBeenCalledTimes(1);
    expect(addHook.mock.calls[0][0]).toBe("agent.turn.before");
    expect(cleanup).toBe(remove);
  });

  it("tags the agent's working directory on a turn", async () => {
    const addHook = vi.fn(
      (
        _name: string,
        _handler: (event: unknown, context: unknown) => Promise<void>,
      ) => vi.fn(),
    );
    contribute({ addHook } as never);
    const handler = addHook.mock.calls[0][1];

    const fetchSpy = vi.fn(async () => ({ ok: true, status: 200 }));
    vi.stubGlobal("fetch", fetchSpy);
    vi.spyOn(console, "error").mockImplementation(() => {});
    // A directory that is not a checkout must not reach the network.
    await handler(
      { agent: { cwd: "/nonexistent/scratch" } },
      { signal: undefined },
    );
    expect(fetchSpy).not.toHaveBeenCalled();
    vi.unstubAllGlobals();
  });
});
