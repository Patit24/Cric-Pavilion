// ====================================================================
// OFFLINE SCORING SYNC QUEUE
// ====================================================================

import { Delivery } from '../types';

export interface QueuedScoringAction {
  id: string; // idempotency key
  matchId: string;
  inningsId: string;
  action: 'record_delivery' | 'undo_delivery';
  payload: Record<string, unknown>;
  timestamp: number;
  status: 'pending' | 'syncing' | 'synced' | 'failed';
  retryCount: number;
}

class OfflineScoringQueue {
  private queueKey = 'cricket_offline_scoring_queue_v1';
  private listeners: Set<(queue: QueuedScoringAction[]) => void> = new Set();

  public getQueue(): QueuedScoringAction[] {
    if (typeof window === 'undefined') return [];
    try {
      const stored = localStorage.getItem(this.queueKey);
      return stored ? JSON.parse(stored) : [];
    } catch {
      return [];
    }
  }

  private saveQueue(queue: QueuedScoringAction[]) {
    if (typeof window === 'undefined') return;
    try {
      localStorage.setItem(this.queueKey, JSON.stringify(queue));
      this.listeners.forEach((cb) => cb(queue));
    } catch (e) {
      console.error('Failed to save offline queue:', e);
    }
  }

  public subscribe(cb: (queue: QueuedScoringAction[]) => void): () => void {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  public enqueueDelivery(inningsId: string, matchId: string, deliveryPayload: Record<string, unknown>): string {
    const queue = this.getQueue();
    const actionId = `sync_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    
    const action: QueuedScoringAction = {
      id: actionId,
      matchId,
      inningsId,
      action: 'record_delivery',
      payload: deliveryPayload,
      timestamp: Date.now(),
      status: 'pending',
      retryCount: 0,
    };

    queue.push(action);
    this.saveQueue(queue);
    return actionId;
  }

  public markSynced(actionId: string) {
    const queue = this.getQueue().filter((item) => item.id !== actionId);
    this.saveQueue(queue);
  }

  public clearQueue() {
    this.saveQueue([]);
  }

  public getPendingCount(): number {
    return this.getQueue().filter((item) => item.status === 'pending').length;
  }
}

export const offlineQueue = new OfflineScoringQueue();
