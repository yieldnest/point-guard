import { EventEmitter } from 'events';

const events = new EventEmitter();

interface SystemState {
  db: any;
  queue: Array<() => Promise<any>>;
}

const system = (function () {
  
  const state: SystemState = {
    db: null,
    queue: []
  }
  
  const on = events.on.bind(events);
  const emit = events.emit.bind(events);

  return {
    on,
    emit,
    get db() { 
      return state.db
    }, 
    set db(value) {
      state.db = value;
    },
    shiftQueue() {
      return state.queue.shift();
    },
    popQueue() {
      return state.queue.pop();
    },
    pushQueue(promise: any) {
      state.queue.push(promise);
    },
    queueLength() {
      return state.queue.length;
    }
  }

})();

export default system;
