export class PromisifyWorker {
  private worker: Worker;

  private requests: Map<
    string,
    { res: (value: unknown) => void; rej: (reason?: any) => any }
  > = new Map();

  constructor(scriptURL: string | URL, options?: WorkerOptions | undefined) {
    this.worker = new Worker(scriptURL, options);
    this.worker.onmessage = this.resolve.bind(this);
  }

  private resolve(e: MessageEvent<any>) {
    console.log("Message received from worker: ", e.data);
    const { uid } = e.data;
    if (typeof uid === "string") {
      this.requests.get(uid)?.res(e.data);
      this.requests.delete(uid);
    } else {
      console.error(
        "PromisifyError received message from a worker without a uid corresponding to any sent message: ",
        e.data
      );
    }
  }

  public postMessage<M extends object | undefined | null, R>(
    message: M,
    transfer: Transferable[] = []
  ): Promise<R> {
    this.worker.postMessage(message, transfer);

    // save promise and resolve later once a matching uid has been received
    const uid = crypto.randomUUID();
    const p = new Promise((res, rej) => {
      this.requests.set(uid, { res, rej });
    });
    const messageWithUid = {
      ...message,
      uid,
    };
    this.worker.postMessage(messageWithUid);
    return p as Promise<R>;
  }

  public terminate() {
    this.worker.terminate();
    this.requests.forEach(({ rej }, key) => {
      rej("Worker was terminated before request could be resolved");
      this.requests.delete(key);
    });
  }
}
