import type { Logger } from '../ports.js';

/**
 * Notification seam (brief §6 stage 9). Real push is deferred; the mock logs.
 * Per §9/§15: never send fake notifications or fake activity. The engine only
 * enqueues a notification for an episode that actually published.
 */
export interface Notification {
  userId: string;
  worldId: string;
  episodeNumber: number;
  title: string;
  body: string;
}

export interface Notifier {
  enqueue(notifications: Notification[]): Promise<void>;
}

export class MockNotifier implements Notifier {
  constructor(private readonly logger?: Logger) {}

  async enqueue(notifications: Notification[]): Promise<void> {
    for (const n of notifications) {
      this.logger?.info('notify', {
        userId: n.userId,
        episode: n.episodeNumber,
        title: n.title,
      });
    }
  }
}
