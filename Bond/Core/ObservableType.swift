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

/// Abstract producer.
/// Can be given an observer (a sink) into which it should put (dispatch) events.
public protocol ObservableType {
  
  /// Type of event objects or values that the observable generates.
  typealias EventType
  
  /// Maximum number of past events that will be sent to each new observer upon registering.
  /// Actual number of sent events may be less if not enough events were generated previously.
  var replayLength: Int { get }
  
  /// Registers the given observer and returns a disposable that can cancel observing.
  func observe(observer: EventType -> Void) -> DisposableType
}

public extension ObservableType {
  
  /// Registers the observer that will receive only events generated after registering.
  /// A better performing verion of observable.skip(observable.replyLength).observe().
  public func observeNew(observer: EventType -> ()) -> DisposableType {
    var skip: Int = replayLength
    return observe { value in
      if skip > 0 {
        skip--
      } else {
        observer(value)
      }
    }
  }
  
  /// Establishes a one-way binding between the source and the bindable's sink
  /// and returns a disposable that can cancel observing.
  public func bindTo<B: BindableType where B.Element == EventType>(bindable: B) -> DisposableType {
    let disposable = SerialDisposable(otherDisposable: nil)
    let sink = bindable.sink(disposable)
    disposable.otherDisposable = observe { value in
      sink(value)
    }
    return disposable
  }
  
  /// Establishes a one-way binding between the source and the bindable's sink
  /// and returns a disposable that can cancel observing.
  public func bindTo<B: BindableType where B.Element == Optional<EventType>>(bindable: B) -> DisposableType {
    let disposable = SerialDisposable(otherDisposable: nil)
    let sink = bindable.sink(disposable)
    disposable.otherDisposable = observe { value in
      sink(value)
    }
    return disposable
  }
  
  /// Transformes each event by the given `transform` function.
  public func map<T>(transform: EventType -> T) -> Observable<T> {
    return Observable(replayLength: replayLength) { sink in
      return observe { event in
        sink(transform(event))
      }
    }
  }
  
  /// Forwards only events for which the given closure returns 'true'.
  public func filter(includeEvent: EventType -> Bool) -> Observable<EventType> {
    return Observable(replayLength: replayLength) { sink in
      return observe { event in
        if includeEvent(event) {
          sink(event)
        }
      }
    }
  }
  
  /// Delivers events onto the given queue.
  public func deliverOn(queue: Queue) -> Observable<EventType> {
    return Observable(replayLength: replayLength) { sink in
      return observe { event in
        queue.async {
          sink(event)
        }
      }
    }
  }
  
  /// Throttles event dispatching for a given number of seconds and then dispatches last event.
  public func throttle(seconds: Queue.TimeInterval, queue: Queue) -> Observable<EventType> {
    return Observable(replayLength: replayLength) { sink in
      var shouldDispatch: Bool = true
      var lastEvent: EventType! = nil
      return observe { event in
        lastEvent = event
        if shouldDispatch {
          shouldDispatch = false
          queue.after(seconds) {
            sink(lastEvent)
            lastEvent = nil
            shouldDispatch = true
          }
        }
      }
    }
  }
  
  /// Ignores first `count` events and forwards any subsequent.
  public func skip(var count: Int) -> Observable<EventType> {
    return Observable(replayLength: max(replayLength - count, 0)) { sink in
      return observe { event in
        if count > 0 {
          count--
        } else {
          sink(event)
        }
      }
    }
  }
  
  /// Sends the given event and then forwards events from the receiver.
  public func startWith(event: EventType) -> Observable<EventType> {
    return Observable(replayLength: replayLength) { sink in
      sink(event)
      return observe { subsequentEvent in
        sink(subsequentEvent)
      }
    }
  }
  
  /// Combines the latest value of the receiver with the latest value from the given observable.
  /// Will not generate an event until both observables have generated one.
  public func combineLatestWith<U: ObservableType>(other: U) -> Observable<(EventType, U.EventType)> {
    return Observable(replayLength: min(replayLength + other.replayLength, 1)) { sink in
      var myEvent: EventType! = nil
      var itsEvent: U.EventType! = nil
      
      let onBothNext = { () -> () in
        if let myEvent = myEvent, let itsEvent = itsEvent {
          sink((myEvent, itsEvent))
        }
      }
      
      let myDisposable = observe { event in
        myEvent = event
        onBothNext()
      }
      
      let itsDisposable = other.observe { event in
        itsEvent = event
        onBothNext()
      }
      
      return CompositeDisposable([myDisposable, itsDisposable])
    }
  }
  
  public func flatMap<U: ObservableType>(strategy: ObservableFlatMapStrategy, transform: EventType -> U) -> Observable<U.EventType> {
    switch strategy {
    case .Latest:
      return map(transform).switchToLatest()
    case .Merge:
      return map(transform).merge()
    }
  }
  
  public func reduce<T>(initial: T, combine: (T, EventType) -> T) -> Observable<T> {
    return Observable { sink in
      var accumulator = initial
      return observe { event in
        accumulator = combine(accumulator, event)
        sink(accumulator)
      }
    }
  }
}

public extension ObservableType where Self: BindableType {
  
  /// Establishes a one-way binding between the source and the bindable's sink
  /// and returns a disposable that can cancel observing.
  public func bidirectionalBindTo<B: BindableType where B: ObservableType, B.EventType == Element, B.Element == EventType>(bindable: B) -> DisposableType {
    let d1 = bindTo(bindable)
    let d2 = bindable.bindTo(self)
    return CompositeDisposable([d1, d2])
  }
}

public extension ObservableType where EventType: OptionalType {
  
  /// Forwards only events that are not `nil`, unwrapped into non-optional type.
  public func ignoreNil() -> Observable<EventType.SomeType> {
    return Observable(replayLength: replayLength) { sink in
      return observe { event in
        if !event.isNil {
          sink(event.value!)
        }
      }
    }
  }
	
  /// Forwards `value` if the event is `nil`, otherwise the event itself.
  public func mapNil(value: EventType.SomeType) -> Observable<EventType.SomeType> {
    return map { event in
      guard let eventValue = event.value else { return value }
      return eventValue
    }
  }
}

public extension ObservableType where EventType: OptionalType, EventType.SomeType == String {
	
  /// Forwards an empty string if the event is `nil`, otherwise the event itself.
  public func mapNilToEmpty() -> Observable<String> {
    return mapNil("")
  }
}

public enum ObservableFlatMapStrategy {
  case Latest
  case Merge
}

public extension ObservableType where EventType: ObservableType {
  
  public func merge() -> Observable<EventType.EventType> {
    return Observable(replayLength: replayLength) { sink in
      let compositeDisposable = CompositeDisposable()
      compositeDisposable += observe { observer in
        compositeDisposable += observer.observe { event in
          sink(event)
        }
      }
      return compositeDisposable
    }
  }
  
  public func switchToLatest() -> Observable<EventType.EventType> {
    return Observable(replayLength: replayLength) { sink in
      let serialDisposable = SerialDisposable(otherDisposable: nil)
      let compositeDisposable = CompositeDisposable([serialDisposable])
      
      compositeDisposable += observe { observer in
        serialDisposable.otherDisposable?.dispose()
        serialDisposable.otherDisposable = observer.observe { event in
          sink(event)
        }
      }
      
      return compositeDisposable
    }
  }
}

public extension ObservableType where EventType: Equatable {
  
  public func distinct() -> Observable<EventType> {
    return Observable(replayLength: replayLength) { sink in
      var lastEvent: EventType? = nil
      return observe { event in
        if lastEvent == nil || lastEvent! != event {
          sink(event)
          lastEvent = event
        }
      }
    }
  }
}

public func combineLatest<A: ObservableType, B: ObservableType>(a: A, _ b: B) -> Observable<(A.EventType, B.EventType)> {
  return a.combineLatestWith(b)
}

public func combineLatest<A: ObservableType, B: ObservableType, C: ObservableType>(a: A, _ b: B, _ c: C) -> Observable<(A.EventType, B.EventType, C.EventType)> {
  return combineLatest(a, b).combineLatestWith(c).map { ($0.0, $0.1, $1) }
}
