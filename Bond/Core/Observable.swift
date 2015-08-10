//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

public enum ObservableLifetime {
  case Normal
  case UntilDisposed
}

public class Observable<EventType>: ObservableType {
  
  /// Type of the sink used by the observable producer.
  public typealias SinkType = EventType -> ()
  
  /// Number of events to replay to each new observer.
  public var replayLength: Int {
    return buffer?.size ?? 0
  }
  
  /// Internal dispatcher that coordinates event dispatching.
  private var dispatcher: Dispatcher<EventType> = Dispatcher()
  
  /// A composite disposable that will be disposed when the observable is deallocated.
  public let deinitDisposable = CompositeDisposable()
  
  /// Internal buffer for event replaying.
  private var buffer: Buffer<EventType>? = nil

  /// Used to manage lifecycle of the observable. Captured by the producer sink. It will hold a
  /// strong reference to self when there is at least one observer registered.
  ///
  /// When all observers are unregistered, the reference will weakify its reference to self.
  /// That means the observable will be deallocated if no one else holds a strong reference to it.
  /// Deallocation will dispose `deinitDisposable` and thus break the connection with the source.
  private weak var selfReference: Reference<Observable<EventType>>?
  
  /// Creates a new observable with the given replay length and the producer that is used
  /// to generate events that will be dispatched to the registered observers.
  ///
  /// Replay length specifies how many previous events should be buffered and then replayed
  /// to each new observer. Observable buffers only latest `replayLength` events, discarding old ones.
  ///
  /// Producer closure will be executed immediately. It will receive a sink into which
  /// events can be dispatched. If producer returns a disposable, the observable will store
  /// it and dispose upon [observable's] deallocation.
  public init(replayLength: Int = 0, @noescape producer: SinkType -> DisposableType?) {
    
    let tmpSelfReference = Reference(self)
    tmpSelfReference.release()
    
    if replayLength > 0 {
      buffer = Buffer(size: replayLength)
    }
    
    let disposable = producer { event in
      tmpSelfReference.object?.buffer?.push(event)
      tmpSelfReference.object?.dispatcher.dispatch(event)
    }
    
    if let disposable = disposable {
      deinitDisposable += disposable
    }
    
    self.selfReference = tmpSelfReference
  }

  /// Registers the given observer and returns a disposable that can cancel observing.
  public func observe(observer: EventType -> ()) -> DisposableType {
    
    selfReference?.retain()
    let disposable = dispatcher.addObserver(observer)
    
    if let buffer = buffer {
      for event in buffer.buffer {
        observer(event)
      }
    }
    
    return BlockDisposable { [weak self] in
      disposable.dispose()
      
      if let unwrappedSelf = self {
        if unwrappedSelf.dispatcher.numberOfObservers == 0 {
          unwrappedSelf.selfReference?.release()
        }
      }
    }
  }
  
  deinit {
    deinitDisposable.dispose()
  }
}
