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

import Foundation

public enum ObservableLifecycle {
  case Normal   /// Normal lifecycle (alive as long as there exists at least one strong reference to it).
  case Managed  /// Normal + retained by the sink given to the producer whenever there is at least one observer.
}

public class EventProducer<EventType>: EventProducerBase<EventType> {
  
  /// Type of the sink used by the observable producer.
  public typealias SinkType = EventType -> ()
  
  /// Number of events to replay to each new observer.
  public override var replayLength: Int {
    return buffer?.size ?? 0
  }
  
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
  private weak var selfReference: Reference<EventProducer<EventType>>? = nil
  
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
    super.init()
    
    let tmpSelfReference = Reference(self)
    tmpSelfReference.release()
    
    if replayLength > 0 {
      buffer = Buffer(size: replayLength)
    }
    
    let disposable = producer { event in
      tmpSelfReference.object?.next(event)
    }
    
    if let disposable = disposable {
      deinitDisposable += disposable
    }
    
    self.selfReference = tmpSelfReference
  }
  
  public init(replayLength: Int = 0) {
    lifecycle = .Normal
    
    if replayLength > 0 {
      buffer = Buffer(size: replayLength)
    }
    
    super.init()
  }
  
  /// Sends an event to the observers
  public override func next(event: EventType) {
    buffer?.push(event)
    super.next(event)
  }
  
  /// Registers the given observer and returns a disposable that can cancel observing.
  public override func observe(observer: EventType -> ()) -> DisposableType {
    
    if lifecycle == .Managed {
      selfReference?.retain()
    }
    
    let eventProducerBaseDisposable = super.observe(observer)
    
    if let buffer = buffer {
      for event in buffer.buffer {
        observer(event)
      }
    }
    
    let observerDisposable = BlockDisposable { [weak self] in
      eventProducerBaseDisposable.dispose()
      
      if let unwrappedSelf = self {
        if unwrappedSelf.numberOfObservers == 0 {
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


extension EventProducer: BindableType {
  
  /// Creates a new sink that can be used to update the receiver.
  /// Optionally accepts a disposable that will be disposed on receiver's deinit.
  public func sink(disconnectDisposable: DisposableType?) -> EventType -> () {
    
    if let disconnectDisposable = disconnectDisposable {
      deinitDisposable += disconnectDisposable
    }
    
    return { [weak self] value in
      self?.next(value)
    }
  }
}
