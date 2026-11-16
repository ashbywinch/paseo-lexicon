import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["server/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "clover"],
      reportsDirectory: "coverage",
    },
  },
});
