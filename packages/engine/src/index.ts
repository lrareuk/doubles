export * from './ports.js';
export * from './context.js';
export * from './ai/AIClient.js';
export { MockAIClient } from './ai/MockAIClient.js';
export { ClaudeAIClient, type ClaudeAIClientOptions } from './ai/ClaudeAIClient.js';
export * from './moderation/Moderator.js';
export * from './notify/Notifier.js';
export * from './game/index.js';
export * from './runEpisode.js';
export * as Prompts from './prompts/index.js';

import { MockAIClient } from './ai/MockAIClient.js';
import { ClaudeAIClient } from './ai/ClaudeAIClient.js';
import type { AIClient } from './ai/AIClient.js';

export interface AIClientEnv {
  AI_PROVIDER?: string;
  ANTHROPIC_API_KEY?: string;
  DOUBLES_MODEL_PLAN?: string;
  DOUBLES_MODEL_BEAT?: string;
  DOUBLES_MODEL_RECAP?: string;
  DOUBLES_USE_BATCH?: string;
}

/**
 * Select the AI implementation by env (brief §6). Defaults to mock so the loop
 * runs with no key. `AI_PROVIDER=claude` switches to the real Anthropic client.
 */
export function createAIClient(env: AIClientEnv): AIClient {
  if ((env.AI_PROVIDER ?? 'mock').toLowerCase() === 'claude') {
    if (!env.ANTHROPIC_API_KEY) {
      throw new Error('AI_PROVIDER=claude requires ANTHROPIC_API_KEY');
    }
    return new ClaudeAIClient({
      apiKey: env.ANTHROPIC_API_KEY,
      models: {
        plan: env.DOUBLES_MODEL_PLAN ?? 'claude-sonnet-4-6',
        beat: env.DOUBLES_MODEL_BEAT ?? 'claude-haiku-4-5',
        recap: env.DOUBLES_MODEL_RECAP ?? 'claude-haiku-4-5',
      },
      useBatch: (env.DOUBLES_USE_BATCH ?? 'true').toLowerCase() !== 'false',
    });
  }
  return new MockAIClient();
}
