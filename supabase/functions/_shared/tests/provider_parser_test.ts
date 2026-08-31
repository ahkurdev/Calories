import { parseOpenCodeResponse } from "../ai/providers/opencode_zen_provider.ts";
import { parseOpenRouterResponse } from "../ai/providers/openrouter_provider.ts";

Deno.test("OpenRouter parser extracts chat completion content", () => {
  const content = parseOpenRouterResponse({
    choices: [{ message: { content: '{"status":"success"}' } }],
  });
  if (content !== '{"status":"success"}') throw new Error("Parser failed");
});

Deno.test("OpenCode parser extracts compatible chat completion content", () => {
  const content = parseOpenCodeResponse({
    choices: [{ message: { content: '{"status":"success"}' } }],
  });
  if (content !== '{"status":"success"}') throw new Error("Parser failed");
});
