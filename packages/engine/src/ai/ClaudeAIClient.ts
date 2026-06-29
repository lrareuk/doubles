import { EpisodePlan, GeneratedBeat, GeneratedRecap, type PlannedBeat, type TokenUsage } from '@doubles/shared';
import type { WorldContext, RecapInput } from '../context.js';
import type { AIClient, PlanResult, BeatsResult, RecapResult } from './AIClient.js';
import { zeroUsage } from './AIClient.js';
import { PLAN_EPISODE, GENERATE_BEAT, WRITE_RECAP } from '../prompts/index.js';

/**
 * Real Anthropic implementation (brief §6). Honours model routing
 * (Sonnet plan / Haiku beats+recaps), the Batch API for nightly generation, and
 * prompt caching for the stable cast block. The SDK is imported dynamically so
 * the default mock path needs no dependency or key.
 */
export interface ClaudeModelConfig {
  plan: string; // claude-sonnet-4-6
  beat: string; // claude-haiku-4-5
  recap: string; // claude-haiku-4-5
}

export interface ClaudeAIClientOptions {
  apiKey: string;
  models?: Partial<ClaudeModelConfig>;
  /** Use the Batch API for beat generation (50% cheaper, async). */
  useBatch?: boolean;
  /** Poll interval for batch completion, ms. */
  batchPollMs?: number;
}

const DEFAULT_MODELS: ClaudeModelConfig = {
  plan: 'claude-sonnet-4-6',
  beat: 'claude-haiku-4-5',
  recap: 'claude-haiku-4-5',
};

// Minimal structural types for the bits of the SDK we touch (avoids a hard dep).
interface AnthropicLike {
  messages: {
    create(args: unknown): Promise<MessageResponse>;
    batches: {
      create(args: unknown): Promise<{ id: string }>;
      retrieve(id: string): Promise<{ processing_status: string }>;
      results(id: string): AsyncIterable<BatchResultItem>;
    };
  };
}
interface MessageResponse {
  content: { type: string; text?: string }[];
  usage?: {
    input_tokens?: number;
    output_tokens?: number;
    cache_read_input_tokens?: number;
  };
}
interface BatchResultItem {
  custom_id: string;
  result: { type: string; message?: MessageResponse };
}

export class ClaudeAIClient implements AIClient {
  private clientPromise: Promise<AnthropicLike> | null = null;
  private readonly models: ClaudeModelConfig;
  private readonly useBatch: boolean;
  private readonly batchPollMs: number;

  constructor(private readonly opts: ClaudeAIClientOptions) {
    this.models = { ...DEFAULT_MODELS, ...opts.models };
    this.useBatch = opts.useBatch ?? true;
    this.batchPollMs = opts.batchPollMs ?? 5000;
  }

  private async client(): Promise<AnthropicLike> {
    if (!this.clientPromise) {
      this.clientPromise = (async () => {
        // Dynamic import keeps @anthropic-ai/sdk optional for the mock path.
        const mod = (await import('@anthropic-ai/sdk')) as unknown as {
          default: new (o: { apiKey: string }) => AnthropicLike;
        };
        const Anthropic = mod.default;
        return new Anthropic({ apiKey: this.opts.apiKey });
      })();
    }
    return this.clientPromise;
  }

  async planEpisode(context: WorldContext): Promise<PlanResult> {
    const client = await this.client();
    const res = await client.messages.create({
      model: this.models.plan,
      max_tokens: 8000,
      system: [
        { type: 'text', text: PLAN_EPISODE.system(context), cache_control: { type: 'ephemeral' } },
      ],
      messages: [{ role: 'user', content: PLAN_EPISODE.user(context) }],
    });
    const plan = EpisodePlan.parse(extractJson(textOf(res)));
    return { plan, usage: usageOf(res) };
  }

  async generateBeats(beats: PlannedBeat[], context: WorldContext): Promise<BeatsResult> {
    if (beats.length === 0) return { beats: [], usage: zeroUsage() };
    const client = await this.client();
    const system = [
      { type: 'text', text: GENERATE_BEAT.system(context), cache_control: { type: 'ephemeral' } },
    ];

    if (this.useBatch) {
      return this.generateBeatsBatched(client, beats, system);
    }

    // Synchronous fallback: parallel Haiku calls.
    let usage = zeroUsage();
    const results = await Promise.all(
      beats.map(async (b) => {
        const res = await client.messages.create({
          model: this.models.beat,
          max_tokens: 600,
          system,
          messages: [{ role: 'user', content: GENERATE_BEAT.user(b) }],
        });
        usage = addUsage(usage, usageOf(res));
        return parseBeat(textOf(res), b.ref);
      }),
    );
    return { beats: results, usage };
  }

  private async generateBeatsBatched(
    client: AnthropicLike,
    beats: PlannedBeat[],
    system: unknown,
  ): Promise<BeatsResult> {
    const batch = await client.messages.batches.create({
      requests: beats.map((b) => ({
        custom_id: b.ref,
        params: {
          model: this.models.beat,
          max_tokens: 600,
          system,
          messages: [{ role: 'user', content: GENERATE_BEAT.user(b) }],
        },
      })),
    });

    // Poll until the batch ends.
    // eslint-disable-next-line no-constant-condition
    while (true) {
      const status = await client.messages.batches.retrieve(batch.id);
      if (status.processing_status === 'ended') break;
      await delay(this.batchPollMs);
    }

    let usage = zeroUsage();
    const byRef = new Map<string, GeneratedBeat>();
    for await (const item of client.messages.batches.results(batch.id)) {
      if (item.result.type === 'succeeded' && item.result.message) {
        usage = addUsage(usage, usageOf(item.result.message));
        byRef.set(item.custom_id, parseBeat(textOf(item.result.message), item.custom_id));
      }
    }
    // Preserve plan order; drop any the batch failed to produce.
    const ordered = beats.map((b) => byRef.get(b.ref)).filter((x): x is GeneratedBeat => !!x);
    return { beats: ordered, usage };
  }

  async writeRecap(input: RecapInput): Promise<RecapResult> {
    const client = await this.client();
    const res = await client.messages.create({
      model: this.models.recap,
      max_tokens: 800,
      system: [{ type: 'text', text: WRITE_RECAP.system() }],
      messages: [{ role: 'user', content: WRITE_RECAP.user(input) }],
    });
    const recap = GeneratedRecap.parse(extractJson(textOf(res)));
    return { recap, usage: usageOf(res) };
  }
}

// ---- helpers -------------------------------------------------------------
function textOf(res: MessageResponse): string {
  return res.content
    .filter((b) => b.type === 'text')
    .map((b) => b.text ?? '')
    .join('');
}

function usageOf(res: MessageResponse): TokenUsage {
  return {
    inputTokens: res.usage?.input_tokens ?? 0,
    outputTokens: res.usage?.output_tokens ?? 0,
    cachedInputTokens: res.usage?.cache_read_input_tokens ?? 0,
    calls: 1,
  };
}

function addUsage(a: TokenUsage, b: TokenUsage): TokenUsage {
  return {
    inputTokens: a.inputTokens + b.inputTokens,
    outputTokens: a.outputTokens + b.outputTokens,
    cachedInputTokens: a.cachedInputTokens + b.cachedInputTokens,
    calls: a.calls + b.calls,
  };
}

/** Strip code fences and isolate the JSON object the model returned. */
function extractJson(text: string): unknown {
  let t = text.trim();
  if (t.startsWith('```')) {
    t = t.replace(/^```(?:json)?\s*/i, '').replace(/```\s*$/i, '');
  }
  const start = t.indexOf('{');
  const end = t.lastIndexOf('}');
  if (start >= 0 && end > start) t = t.slice(start, end + 1);
  return JSON.parse(t);
}

function parseBeat(text: string, ref: string): GeneratedBeat {
  try {
    return GeneratedBeat.parse(extractJson(text));
  } catch {
    // Tolerate a plain-text beat by wrapping it.
    return { ref, content: text.trim() };
  }
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
