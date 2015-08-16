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

/// Abstraction over a type that can be used to encapsulate a value and observe its changes.
public protocol ScalarType {
  typealias ValueType
  var value: ValueType { get set }
}

/// A type that can be used to encapsulate a value and observe its changes.
public final class Scalar<ValueType>: Observable<ValueType>, ScalarType, BindableType {
  
  /// The underlying sink to dispatch events to.
  private var capturedSink: SinkType! = nil
  
  /// The underlying value.
  /// Changing it generates an event that's sent to the registered observers.
  public var value: ValueType {
    didSet {
      capturedSink(value)
    }
  }
  
  /// Creates a new scalar with the initial value.
  public init(_ value: ValueType) {
    self.value = value
    
    var capturedSink: SinkType! = nil
    super.init(replayLength: 1, lifecycle: .Normal) { sink in
      capturedSink = sink
      return nil
    }
    
    self.capturedSink = capturedSink
    self.capturedSink(value)
  }

  /// Updates internal value and generates change event. Same as Scalar.value = x.
  public func set(value: ValueType) {
    self.value = value
  }
  
  /// Creates a new sink that can be used to update the receiver.
  /// Optionally accepts a disposable that will be disposed on receiver's deinit.
  public func sink(disconnectDisposable: DisposableType?) -> ValueType -> () {

    if let disconnectDisposable = disconnectDisposable {
      deinitDisposable += disconnectDisposable
    }
    
    return { [weak self] value in
      self?.value = value
    }
  }
}

public extension ObservableType {
  
  /// Creates a scalar from the observable. If the observable is already a scalar, returns that scalar.
  /// Note that the given observable must have `replayLength` value of at least `1`!
  public func crystallize() -> Scalar<EventType> {
    guard self.replayLength > 0 else {
      fatalError("Dear Sir/Madam, observables that have `replayLength` less than `1` cannot be crystallized!")
    }
    
    if let scalar = self as? Scalar<EventType> {
      return scalar
    }
    
    var capturedValue: EventType! = nil
    observe{ capturedValue = $0 }.dispose()
    
    let scalar = Scalar<EventType>(capturedValue)
    scalar.deinitDisposable += skip(replayLength).bindTo(scalar)
    
    return scalar
  }
}
