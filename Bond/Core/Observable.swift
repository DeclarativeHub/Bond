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

public enum ObservableLifecycle {
  case Normal   /// Normal lifecycle (alive as long as there exists at least one strong reference to it).
  case Managed  /// Normal + retained by the sink given to the producer whenever there is at least one observer.
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

  /// Used to manage lifecycle of the observable when lifetime == .Managed. 
  /// Captured by the producer sink. It will hold a strong reference to self
  /// when there is at least one observer registered.
  ///
  /// When all observers are unregistered, the reference will weakify its reference to self.
  /// That means the observable will be deallocated if no one else holds a strong reference to it.
  /// Deallocation will dispose `deinitDisposable` and thus break the connection with the source.
  private weak var selfReference: Reference<Observable<EventType>>? = nil
  
  /// Consult `ObservableLifetime` for more info.
  public private(set) var lifecycle: ObservableLifecycle
  
  /// Creates a new observable with the given replay length and the producer that is used
  /// to generate events that will be dispatched to the registered observers.
  ///
  /// Replay length specifies how many previous events should be buffered and then replayed
  /// to each new observer. Observable buffers only latest `replayLength` events, discarding old ones.
  ///
  /// Producer closure will be executed immediately. It will receive a sink into which
  /// events can be dispatched. If producer returns a disposable, the observable will store
  /// it and dispose upon [observable's] deallocation.
  public init(replayLength: Int = 0, lifecycle: ObservableLifecycle = .Managed, @noescape producer: SinkType -> DisposableType?) {
    self.lifecycle = lifecycle
    
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
  
  /// Creates a new Observable that replays given value as an event.
  public init(_ value: EventType) {
    lifecycle = .Normal
    buffer = Buffer(size: 1)
    next(value)
  }
  
  /// Sends an event to the observers
  public func next(event: EventType) {
    buffer?.push(event)
    dispatcher.dispatch(event)
  }

  /// Registers the given observer and returns a disposable that can cancel observing.
  public func observe(observer: EventType -> ()) -> DisposableType {
    
    if lifecycle == .Managed {
      selfReference?.retain()
    }
    
    let dispatcherDisposable = dispatcher.addObserver(observer)
    
    if let buffer = buffer {
      for event in buffer.buffer {
        observer(event)
      }
    }
    
    let observerDisposable = BlockDisposable { [weak self] in
      dispatcherDisposable.dispose()
      
      if let unwrappedSelf = self {
        if unwrappedSelf.dispatcher.numberOfObservers == 0 {
          unwrappedSelf.selfReference?.release()
        }
      }
    }
    
    deinitDisposable += observerDisposable
    return observerDisposable
  }
  
  deinit {
    deinitDisposable.dispose()
  }
}

public extension Observable {
  
  /// Observable's value.
  ///
  /// Note that if the receiver is not an instance initialized with Observable(_ value: EventType) initializer
  /// nor any derivation of such instance, this will contain last sent event or nil if not events were sent
  /// or the Observable has replayLength less than 1.
  public var value: EventType! {
    set(newValue) {
      next(newValue)
    }
    get {
      return buffer?.last
    }
  }
}

extension Observable: BindableType {
  
  /// Creates a new sink that can be used to update the receiver.
  /// Optionally accepts a disposable that will be disposed on receiver's deinit.
  public func sink(disconnectDisposable: DisposableType?) -> EventType -> () {
    
    if let disconnectDisposable = disconnectDisposable {
      deinitDisposable += disconnectDisposable
    }
    
    return { [weak self] value in
      self?.value = value
    }
  }
}
