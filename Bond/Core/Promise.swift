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

/// An observable suitable for returning results from asynchronous operations.
public final class Promise<SuccessType, FailureType: ErrorType>: Observable<Future<SuccessType, FailureType>> {
  
  /// Cancel disposable
  private var cancelDisposable: CompositeDisposable! = nil
  
  /// The underlying sink to dispatch events to.
  private var capturedSink: SinkType! = nil
  
  private var numberOfObservers: Int = 0
  
  /// Indicates whether the task that generated the promise should be canceled.
  /// Check this periodically while performing the taks if possible.
  public var isCanceled: Bool {
    return cancelDisposable.isDisposed
  }
  
  public convenience init(value: SuccessType) {
    self.init()
    self.success(value)
  }
  
  public convenience init(error: FailureType) {
    self.init()
    self.failure(error)
  }
  
  /// Creates a new promise.
  public init() {
    let cancelDisposable = CompositeDisposable()
    
    var capturedSink: SinkType! = nil
    super.init(replayLength: 1, lifetime: .Normal) { sink in
      capturedSink = sink
      return cancelDisposable
    }
    
    self.cancelDisposable = cancelDisposable
    self.capturedSink = capturedSink
  }
  
  public func success(value: SuccessType) {
    guard !cancelDisposable.isDisposed else { return }
    capturedSink(Future(value))
  }
  
  public func failure(error: FailureType) {
    guard !cancelDisposable.isDisposed else { return }
    capturedSink(Future(error))
  }
  
  public func onCancel(block: () -> ()) {
    self.cancelDisposable += BlockDisposable {
      block()
    }
  }
  
  /// Promise will be cancelled the first time number of observers drops to zero.
  public override func observe(observer: Future<SuccessType, FailureType> -> ()) -> DisposableType {
    numberOfObservers++;
    let disposable = super.observe(observer)
    return BlockDisposable { [weak self] in
      disposable.dispose()
      self?.numberOfObservers--
      if self?.numberOfObservers < 1 {
        self?.cancelDisposable.dispose()
      }
    }
  }
}


public extension ObservableType where EventType: FutureType, EventType.FailureType: ErrorType {
  
  public func onSuccess(callback: EventType.SuccessType -> Void) -> DisposableType {
    return observe { future in
      switch future.outcome {
      case .Left(let value):
        callback(value)
      default:
        break
      }
    }
  }
  
  public func onFailure(callback: EventType.FailureType -> Void) -> DisposableType {
    return observe { future in
      switch future.outcome {
      case .Right(let error):
        callback(error)
      default:
        break
      }
    }
  }
  
  public func recover(callback: EventType -> EventType.SuccessType) -> Observable<Future<EventType.SuccessType, EventType.FailureType>> {
    return Observable(replayLength: replayLength) { sink in
      return observe { event in
        sink(Future(callback(event)))
      }
    }
  }
  
  public func andThen(callback: EventType -> Void) -> Observable<Future<EventType.SuccessType, EventType.FailureType>> {
    return Observable(replayLength: replayLength) { sink in
      return observe { event in
        callback(event)
        sink(Future(event.outcome))
      }
    }
  }
  
  public func promoteValue() -> Observable<EventType.SuccessType> {
    return Observable(replayLength: replayLength) { sink in
      return observe { future in
        switch future.outcome {
        case .Left(let value):
          sink(value)
        default:
          break
        }
      }
    }
  }
  
  public func promoteError() -> Observable<EventType.FailureType> {
    return Observable(replayLength: replayLength) { sink in
      return observe { future in
        switch future.outcome {
        case .Right(let error):
          sink(error)
        default:
          break
        }
      }
    }
  }
}
