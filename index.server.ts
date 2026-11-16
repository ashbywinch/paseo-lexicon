// Tag the transcription shim with the repository an agent is working in.
//
// Dictation carries no repository of its own: the request comes from the daemon, not from a process
// with a working directory. This plugin supplies the missing context by reporting the repo of the
// agent whose turn just started. The shim unions every repository reported in its window, so several
// active repos are all covered rather than the last one winning.

import type { PluginServerContext } from "@getpaseo/plugin/server";
import { tagRepo } from "./server/tag";

export default function contribute(server: PluginServerContext) {
  const remove = server.addHook(
    "agent.turn.before",
    async ({ agent }, { signal }) => {
      await tagRepo(agent.cwd, signal);
    },
  );
  return remove;
}
