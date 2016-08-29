//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

import ReactiveKit
import Foundation

public struct DynamicSubject<Target: Deallocatable, Element>: SubjectProtocol, BindableProtocol {

  private var target: Target?
  private var signal: Signal<Void, NoError>
  private let getter: (Target) -> Element
  private let setter: (Target, Element) -> Void
  private let subject = PublishSubject<Void, NoError>()
  
  public init(target: Target,
              signal: Signal<Void, NoError>,
              get: @escaping (Target) -> Element,
              set: @escaping (Target, Element) -> Void) {
    self.target = target
    self.signal = signal
    self.getter = get
    self.setter = set
  }

  public func on(_ event: Event<Element, NoError>) {
    if case .next(let element) = event, let target = target {
      setter(target, element)
      subject.next()
    }
  }

  public func observe(with observer: @escaping (Event<Element, NoError>) -> Void) -> Disposable {
    guard let target = target else { observer(.completed); return NonDisposable.instance }
    let getter = self.getter
    return signal.merge(with: subject).map { [weak target] () -> Element? in
      if let target = target {
        return getter(target)
      } else {
        return nil
      }
    }.ignoreNil().observe(with: observer)    
  }
  
  public func bind(signal: Signal<Element, NoError>) -> Disposable {
    if let target = target {
      let setter = self.setter
      let subject = self.subject
      return signal.take(until: target.bnd_deallocated).observe { [weak target] event in
        ImmediateOnMainExecutionContext { [weak target] in
          switch event {
          case .next(let element):
            guard let target = target else { return }
            setter(target, element)
            subject.next()
          case .failed(let error):
            subject.failed(error)
          case .completed:
            subject.completed()
          }
        }
      }
    } else {
      return NonDisposable.instance
    }
  }
}
