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

/// Coordinates a collection of observables and a dispatching of events to them.
public final class Dispatcher<EventType> {
  
  private var isDispatchInProgress: Bool = false
  private var observers: [Int64:EventType -> Void] = [:]
  private var nextToken: Int64 = 0
  private let lock = NSRecursiveLock(name: "com.swift-bond.Bond.Dispatcher")
  
  /// Number of registered observers.
  public var numberOfObservers: Int {
    return observers.count
  }
  
  /// Dispatches the given event to all registered observers.
  public func dispatch(event: EventType) {
    guard !isDispatchInProgress else { return }
    
    lock.lock()
    isDispatchInProgress = true
    for (_, send) in observers {
      send(event)
    }
    isDispatchInProgress = false
    lock.unlock()
  }
  
  /// Registers the given observer and returns a disposable that can cancel observing.
  public func addObserver(observer: EventType -> Void) -> DisposableType {
    lock.lock()
    let token = nextToken
    nextToken = nextToken + 1
    lock.unlock()
    
    observers[token] = observer
    return DispatcherDisposable(dispatcher: self, token: token)
  }
  
  private func removeObserver(disposable: DispatcherDisposable<EventType>) {
    observers.removeValueForKey(disposable.token)
  }
}

public final class DispatcherDisposable<EventType>: DisposableType {
  
  private var dispatcher: Dispatcher<EventType>!
  private var token: Int64
  
  public var isDisposed: Bool {
    return dispatcher == nil
  }
  
  private init(dispatcher: Dispatcher<EventType>, token: Int64) {
    self.dispatcher = dispatcher
    self.token = token
  }
  
  public func dispose() {
    if let dispatcher = dispatcher {
      dispatcher.removeObserver(self)
      self.dispatcher = nil
    }
  }
}
