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

public typealias DynamicSubject<Element> = FailableDynamicSubject<Element, Never>

/// Dynamic subject is both a signal and an observer (and a binding target).
/// It emits events when the underlying signal emits an event. Elements emitted
/// are read from the target using the `getter` closure.
/// Observing a signal will a dynamic subject will update the underlying target
/// using the `setter` closure on each next event.
public struct FailableDynamicSubject<Element, Error: Swift.Error>: SubjectProtocol, BindableProtocol {

    private weak var target: AnyObject?
    private var signal: Signal<Void, Error>
    private let context: ExecutionContext
    private let getter: (AnyObject) -> Result<Element, Error>
    private let setter: (AnyObject, Element) -> Void
    private let subject = PassthroughSubject<Void, Error>()
    private let triggerEventOnSetting: Bool

    public init<Target: Deallocatable>(target: Target,
                                       signal: Signal<Void, Error>,
                                       context: ExecutionContext,
                                       get: @escaping (Target) -> Result<Element, Error>,
                                       set: @escaping (Target, Element) -> Void,
                                       triggerEventOnSetting: Bool = true) {
        self.target = target
        self.signal = signal
        self.context = context
        self.getter = { get($0 as! Target) }
        self.setter = { set($0 as! Target, $1) }
        self.triggerEventOnSetting = triggerEventOnSetting
    }

    public init<Target: Deallocatable>(target: Target,
                                       signal: Signal<Void, Error>,
                                       context: ExecutionContext,
                                       get: @escaping (Target) -> Element,
                                       set: @escaping (Target, Element) -> Void,
                                       triggerEventOnSetting: Bool = true) {
        self.target = target
        self.signal = signal
        self.context = context
        self.getter = { .success(get($0 as! Target)) }
        self.setter = { set($0 as! Target, $1) }
        self.triggerEventOnSetting = triggerEventOnSetting
    }

    private init(_target: AnyObject,
                 signal: Signal<Void, Error>,
                 context: ExecutionContext,
                 get: @escaping (AnyObject) -> Result<Element, Error>,
                 set: @escaping (AnyObject, Element) -> Void,
                 triggerEventOnSetting: Bool = true) {
        self.target = _target
        self.signal = signal
        self.context = context
        self.getter = { get($0) }
        self.setter = { set($0, $1) }
        self.triggerEventOnSetting = triggerEventOnSetting
    }

    public func on(_ event: Signal<Element, Error>.Event) {
        if case .next(let element) = event, let target = target {
            setter(target, element)
            if triggerEventOnSetting {
                subject.send(())
            }
        }
    }

    public func observe(with observer: @escaping (Signal<Element, Error>.Event) -> Void) -> Disposable {
        guard let target = target else { observer(.completed); return NonDisposable.instance }
        let getter = self.getter
        return signal.prepend(()).merge(with: subject).tryMap { [weak target] () -> Result<Element?, Error> in
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
        }.ignoreNils().prefix(untilOutputFrom: (target as! Deallocatable).deallocated).observe(with: observer)
    }

    public func bind(signal: Signal<Element, Never>) -> Disposable {
        if let target = target {
            let setter = self.setter
            let subject = self.subject
            let context = self.context
            let triggerEventOnSetting = self.triggerEventOnSetting
            return signal.prefix(untilOutputFrom: (target as! Deallocatable).deallocated).observe { [weak target] event in
                context.execute { [weak target] in
                    switch event {
                    case .next(let element):
                        guard let target = target else { return }
                        setter(target, element)
                        if triggerEventOnSetting {
                            subject.send(())
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
                                    from setTransform: @escaping (U) -> Element) -> FailableDynamicSubject<U, Error>! {
        guard let target = target else { return nil }

        return FailableDynamicSubject<U, Error>(
            _target: target,
            signal: signal,
            context: context,
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

extension ReactiveExtensions where Base: Deallocatable {

    public func dynamicSubject<Element>(signal: Signal<Void, Never>,
                                        context: ExecutionContext,
                                        triggerEventOnSetting: Bool = true,
                                        get: @escaping (Base) -> Element,
                                        set: @escaping (Base, Element) -> Void) -> DynamicSubject<Element> {
        return DynamicSubject(target: base, signal: signal, context: context, get: get, set: set, triggerEventOnSetting: triggerEventOnSetting)
    }
}

extension ReactiveExtensions where Base: Deallocatable, Base: BindingExecutionContextProvider {

    public func dynamicSubject<Element>(signal: Signal<Void, Never>,
                                        triggerEventOnSetting: Bool = true,
                                        get: @escaping (Base) -> Element,
                                        set: @escaping (Base, Element) -> Void) -> DynamicSubject<Element> {
        return dynamicSubject(signal: signal, context: base.bindingExecutionContext, triggerEventOnSetting: triggerEventOnSetting, get: get, set: set)
    }
}
