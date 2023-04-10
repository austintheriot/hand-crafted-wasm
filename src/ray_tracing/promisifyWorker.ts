export type PromisePoolObject = { res: (value: unknown) => void; rej: (reason?: any) => any };

export class PromisifyWorker {
  private worker: Worker;
  private uid = 0n;
  private promisePool: Map<
    BigInt,
    PromisePoolObject
  > = new Map();

  constructor(scriptURL: string | URL, options?: WorkerOptions | undefined) {
    this.worker = new Worker(scriptURL, options);
    this.worker.onmessage = this.resolve.bind(this);
  }

  private getNewUid(): BigInt {
    const uid = this.uid;
    this.uid += 1n;
    return uid;
  }

  /** 
   * Match up a message received in main thread with the promise
   * that was created when the original message was sent from the main thread.
   */
  private resolve(e: MessageEvent<any>) {
    const { uid } = e.data;
    if (typeof uid === "bigint") {
      this.promisePool.get(uid)?.res(e.data);
      this.promisePool.delete(uid);
    } else {
      console.error(
        "PromisifyError received message from a worker without a uid corresponding to any sent message: ",
        e.data
      );
    }
  }

  /** 
   * Send a message to a worker thread.
   * 
   * The returned promise is resolved once the worker thread sends a 
   * message back to the main thread with a matching uid.
   */
  public postMessage<M extends object | undefined | null, R>(
    message: M,
    transfer: Transferable[] = []
  ): Promise<R> {
    // save promise and resolve later once a matching uid has been received
    const uid = this.getNewUid();
    const p = new Promise((res, rej) => {
      this.promisePool.set(uid, { res, rej });
    });
    this.worker.postMessage(
      {
        ...message,
        uid,
      },
      transfer
    );
    return p as Promise<R>;
  }

  /**
   * Rejects all remaining postMessage promises and deletes all internal data
   */
  public terminate() {
    this.worker.terminate();
    this.promisePool.forEach(({ rej }, key) => {
      rej("Worker was terminated before request could be resolved");
      this.promisePool.delete(key);
    });
  }
}
