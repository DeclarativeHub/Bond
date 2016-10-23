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

public struct DynamicSubject2<Target: Deallocatable, Element, Error: Swift.Error>: SubjectProtocol, BindableProtocol {

  private weak var target: Target?
  private var signal: Signal<Void, Error>
  private let getter: (Target) -> Result<Element, Error>
  private let setter: (Target, Element) -> Void
  private let subject = PublishSubject<Void, Error>()
  private let triggerEventOnSetting: Bool

  public init(target: Target,
              signal: Signal<Void, Error>,
              get: @escaping (Target) -> Result<Element, Error>,
              set: @escaping (Target, Element) -> Void,
              triggerEventOnSetting: Bool = true) {
    self.target = target
    self.signal = signal
    self.getter = get
    self.setter = set
    self.triggerEventOnSetting = triggerEventOnSetting
  }

  public init(target: Target,
              signal: Signal<Void, Error>,
              get: @escaping (Target) -> Element,
              set: @escaping (Target, Element) -> Void,
              triggerEventOnSetting: Bool = true) {
    self.target = target
    self.signal = signal
    self.getter = { .success(get($0)) }
    self.setter = set
    self.triggerEventOnSetting = triggerEventOnSetting
  }

  public func on(_ event: Event<Element, Error>) {
    if case .next(let element) = event, let target = target {
      setter(target, element)
      if triggerEventOnSetting {
        subject.next()
      }
    }
  }

  public func observe(with observer: @escaping (Event<Element, Error>) -> Void) -> Disposable {
    guard let target = target else { observer(.completed); return NonDisposable.instance }
    let getter = self.getter
    return signal.start(with: ()).merge(with: subject).tryMap { [weak target] () -> Result<Element?, Error> in
      if let target = target {
        switch getter(target) {
        case .success(let element):
          return .success(element)
        case .failure(let error):
          return .failure(error)
        }
      } else {
        return .success(nil)
      }
      }.ignoreNil().take(until: target.bnd_deallocated).observe(with: observer)
  }

  public func bind(signal: Signal<Element, NoError>) -> Disposable {
    if let target = target {
      let setter = self.setter
      let subject = self.subject
      let triggerEventOnSetting = self.triggerEventOnSetting
      return signal.take(until: target.bnd_deallocated).observe { [weak target] event in
        ImmediateOnMainExecutionContext { [weak target] in
          switch event {
          case .next(let element):
            guard let target = target else { return }
            setter(target, element)
            if triggerEventOnSetting {
              subject.next()
            }
          default:
            break
          }
        }
      }
    } else {
      return NonDisposable.instance
    }
  }

  /// Current value if the target is alive, otherwise `nil`.
  public var value: Element! {
    if let target = target {
      switch getter(target) {
      case .success(let value):
        return value
      case .failure:
        return nil
      }
    } else {
      return nil
    }
  }

  /// Transform the `getter` and `setter` by applying a `transform` on them.
  public func bidirectionalMap<U>(to getTransform: @escaping (Element) -> U,
                               from setTransform: @escaping (U) -> Element) -> DynamicSubject2<Target, U, Error>! {
    guard let target = target else { return nil }

    return DynamicSubject2<Target, U, Error>(
      target: target,
      signal: signal,
      get: { [getter] (target) -> Result<U, Error> in
        switch getter(target) {
        case .success(let value):
          return .success(getTransform(value))
        case .failure(let error):
          return .failure(error)
        }
      },
      set: { [setter] (target, element) in
        setter(target, setTransform(element))
      }
    )
  }
}

public typealias DynamicSubject<Target: Deallocatable, Element> = DynamicSubject2<Target, Element, NoError>
