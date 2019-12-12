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

import Foundation
import ObjectiveC
import ReactiveKit

#if !BUILDING_WITH_XCODE
import BNDProtocolProxyBase
#endif

public class ProtocolProxy: BNDProtocolProxyBase {

    private var invokers: [Selector: (BNDInvocation) -> Void] = [:]
    private var handlers: [Selector: Any] = [:]
    private let propertyController: ProtocolProxyPropertyController

    public init(object: NSObject, `protocol`: Protocol, setter: Selector) {
        self.propertyController = SelectorProtocolProxyPropertyController(object: object, selector: setter)
        super.init(with: `protocol`)
    }

    public init(protocol: Protocol, propertyController: ProtocolProxyPropertyController) {
        self.propertyController = propertyController
        super.init(with: `protocol`)
    }

    public override var forwardTo: NSObject? {
        get {
            return super.forwardTo
        }
        set {
            super.forwardTo = newValue
            registerDelegate()
        }
    }

    public override func hasHandler(for selector: Selector) -> Bool {
        return invokers[selector] != nil
    }

    public override func handle(_ invocation: BNDInvocation) {
        guard let invoker = invokers[invocation.selector] else { return }
        invocation.retainArguments()
        invoker(invocation)
    }

    private func registerInvoker0<R>(for selector: Selector, block: @escaping () -> R) -> Disposable {
        invokers[selector] = { invocation in
            let result = block()
            invocation.writeReturnValue(result)
        }
        registerDelegate()
        return MainBlockDisposable { [weak self] in
            self?.invokers[selector] = nil
            self?.registerDelegate()
        }
    }

    private func registerInvoker1<T, R>(for selector: Selector, block: @escaping (T) -> R) -> Disposable {
        invokers[selector] = { invocation in
            let result = block(invocation.readArgument(2))
            invocation.writeReturnValue(result)
        }
        registerDelegate()
        return MainBlockDisposable { [weak self] in
            self?.invokers[selector] = nil
            self?.registerDelegate()
        }
    }

    private func registerInvoker2<T, U, R>(for selector: Selector, block: @escaping (T, U) -> R) -> Disposable {
        invokers[selector] = { invocation in
            let result = block(invocation.readArgument(2), invocation.readArgument(3))
            invocation.writeReturnValue(result)
        }
        registerDelegate()
        return MainBlockDisposable { [weak self] in
            self?.invokers[selector] = nil
            self?.registerDelegate()
        }
    }

    private func registerInvoker3<T, U, V, R>(for selector: Selector, block: @escaping (T, U, V) -> R) -> Disposable {
        invokers[selector] = { invocation in
            let result = block(invocation.readArgument(2), invocation.readArgument(3), invocation.readArgument(4))
            invocation.writeReturnValue(result)
        }
        registerDelegate()
        return MainBlockDisposable { [weak self] in
            self?.invokers[selector] = nil
            self?.registerDelegate()
        }
    }

    private func registerInvoker4<T, U, V, W, R>(for selector: Selector, block: @escaping (T, U, V, W) -> R) -> Disposable {
        invokers[selector] = { invocation in
            let result = block(invocation.readArgument(2), invocation.readArgument(3), invocation.readArgument(4), invocation.readArgument(5))
            invocation.writeReturnValue(result)
        }
        registerDelegate()
        return MainBlockDisposable { [weak self] in
            self?.invokers[selector] = nil
            self?.registerDelegate()
        }
    }

    private func registerInvoker5<T, U, V, W, X, R>(for selector: Selector, block: @escaping (T, U, V, W, X) -> R) -> Disposable {
        invokers[selector] = { invocation in
            let result = block(invocation.readArgument(2), invocation.readArgument(3), invocation.readArgument(4), invocation.readArgument(5), invocation.readArgument(6))
            invocation.writeReturnValue(result)
        }
        registerDelegate()
        return MainBlockDisposable { [weak self] in
            self?.invokers[selector] = nil
            self?.registerDelegate()
        }
    }

    private func _signal<S>(for selector: Selector, registerInvoker: @escaping (PassthroughSubject<S, Never>) -> Disposable) -> SafeSignal<S>{
        if let signal = handlers[selector] {
            return signal as! SafeSignal<S>
        } else {
            let signal = SafeSignal<S> { [weak self] observer in
                let subject = PassthroughSubject<S, Never>()
                let disposable = CompositeDisposable()
                disposable += registerInvoker(subject)
                disposable += subject.observe(with: observer)
                disposable += MainBlockDisposable { [weak self] in
                    self?.handlers[selector] = nil
                }
                return disposable
            }.share(limit: 0)
            handlers[selector] = signal
            return signal
        }
    }

    /// Maps the given protocol method to a signal. Whenever the method on the target object is called,
    /// the framework will call the provided `dispatch` closure that you can use to generate a signal.
    ///
    /// - parameter selector: Selector of the method to map.
    /// - parameter dispatch: A closure that dispatches calls to the given PassthroughSubject.
    public func signal<S, R>(for selector: Selector, dispatch: @escaping (PassthroughSubject<S, Never>) -> R) -> SafeSignal<S> {
        return _signal(for: selector) { [weak self] subject in
            guard let me = self else { return NonDisposable.instance }
            return me.registerInvoker0(for: selector) { () -> R in
                return dispatch(subject)
            }
        }
    }

    /// Maps the given protocol method to a signal. Whenever the method on the target object is called,
    /// the framework will call the provided `dispatch` closure that you can use to generate a signal.
    ///
    /// - parameter selector: Selector of the method to map.
    /// - parameter dispatch: A closure that dispatches calls to the given PassthroughSubject.
    ///
    /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
    /// in place of generic parameter A and R!
    public func signal<A, S, R>(for selector: Selector, dispatch: @escaping (PassthroughSubject<S, Never>, A) -> R) -> SafeSignal<S> {
        return _signal(for: selector) { [weak self] subject in
            guard let me = self else { return NonDisposable.instance }
            return me.registerInvoker1(for: selector) { (a: A) -> R in
                return dispatch(subject, a)
            }
        }
    }

    /// Maps the given protocol method to a signal. Whenever the method on the target object is called,
    /// the framework will call the provided `dispatch` closure that you can use to generate a signal.
    ///
    /// - parameter selector: Selector of the method to map.
    /// - parameter dispatch: A closure that dispatches calls to the given PassthroughSubject.
    ///
    /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
    /// in place of generic parameters A, B and R!
    public func signal<A, B, S, R>(for selector: Selector, dispatch: @escaping (PassthroughSubject<S, Never>, A, B) -> R) -> SafeSignal<S> {
        return _signal(for: selector) { [weak self] subject in
            guard let me = self else { return NonDisposable.instance }
            return me.registerInvoker2(for: selector) { (a: A, b: B) -> R in
                return dispatch(subject, a, b)
            }
        }
    }

    /// Maps the given protocol method to a signal. Whenever the method on the target object is called,
    /// the framework will call the provided `dispatch` closure that you can use to generate a signal.
    ///
    /// - parameter selector: Selector of the method to map.
    /// - parameter dispatch: A closure that dispatches calls to the given PassthroughSubject.
    ///
    /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
    /// in place of generic parameters A, B, C and R!
    public func signal<A, B, C, S, R>(for selector: Selector, dispatch: @escaping (PassthroughSubject<S, Never>, A, B, C) -> R) -> SafeSignal<S> {
        return _signal(for: selector) { [weak self] subject in
            guard let me = self else { return NonDisposable.instance }
            return me.registerInvoker3(for: selector) { (a: A, b: B, c: C) -> R in
                return dispatch(subject, a, b, c)
            }
        }
    }

    /// Maps the given protocol method to a signal. Whenever the method on the target object is called,
    /// the framework will call the provided `dispatch` closure that you can use to generate a signal.
    ///
    /// - parameter selector: Selector of the method to map.
    /// - parameter dispatch: A closure that dispatches calls to the given PassthroughSubject.
    ///
    /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
    /// in place of generic parameters A, B, C, D and R!
    public func signal<A, B, C, D, S, R>(for selector: Selector, dispatch: @escaping (PassthroughSubject<S, Never>, A, B, C, D) -> R) -> SafeSignal<S> {
        return _signal(for: selector) { [weak self] subject in
            guard let me = self else { return NonDisposable.instance }
            return me.registerInvoker4(for: selector) { (a: A, b: B, c: C, d: D) -> R in
                return dispatch(subject, a, b, c, d)
            }
        }
    }

    /// Maps the given protocol method to a signal. Whenever the method on the target object is called,
    /// the framework will call the provided `dispatch` closure that you can use to generate a signal.
    ///
    /// - parameter selector: Selector of the method to map.
    /// - parameter dispatch: A closure that dispatches calls to the given PassthroughSubject.
    ///
    /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
    /// in place of generic parameters A, B, C, D, E and R!
    public func signal<A, B, C, D, E, S, R>(for selector: Selector, dispatch: @escaping (PassthroughSubject<S, Never>, A, B, C, D, E) -> R) -> SafeSignal<S> {
        return _signal(for: selector) { [weak self] subject in
            guard let me = self else { return NonDisposable.instance }
            return me.registerInvoker5(for: selector) { (a: A, b: B, c: C, d: D, e: E) -> R in
                return dispatch(subject, a, b, c, d, e)
            }
        }
    }

    public override func conforms(to aProtocol: Protocol) -> Bool {
        if protocol_isEqual(`protocol`, self.`protocol`) {
            return true
        } else {
            return super.conforms(to: `protocol`)
        }
    }

    public override func responds(to aSelector: Selector!) -> Bool {
        if invokers[aSelector] != nil {
            return true
        } else if forwardTo?.responds(to: aSelector) ?? false {
            return true
        } else {
            return super.responds(to: aSelector)
        }
    }

    private func registerDelegate() {
        if let previous = propertyController.delegate, previous !== self, forwardTo == nil {
            super.forwardTo = previous
        }
        propertyController.delegate = nil
        propertyController.delegate = self
    }

    deinit {
        propertyController.delegate = nil
    }
}

extension ProtocolProxy {

    /// Provides a feed for specified protocol method.
    ///
    /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
    public func feed<S, A, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A) -> R) -> Disposable {
        return signal(for: selector) { (_: PassthroughSubject<Void, Never>, a1: A) -> R in
            return map(property.value, a1)
        }.observe { _ in }
    }

    /// Provides a feed for specified protocol method.
    ///
    /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
    public func feed<S, A, B, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B) -> R) -> Disposable {
        return signal(for: selector) { (_: PassthroughSubject<Void, Never>, a1: A, a2: B) -> R in
            return map(property.value, a1, a2)
        }.observe { _ in }
    }

    /// Provides a feed for specified protocol method.
    ///
    /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
    public func feed<S, A, B, C, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B, C) -> R) -> Disposable {
        return signal(for: selector) { (_: PassthroughSubject<Void, Never>, a1: A, a2: B, a3: C) -> R in
            return map(property.value, a1, a2, a3)
        }.observe { _ in }
    }

    /// Provides a feed for specified protocol method.
    ///
    /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
    public func feed<S, A, B, C, D, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B, C, D) -> R) -> Disposable {
        return signal(for: selector) { (_: PassthroughSubject<Void, Never>, a1: A, a2: B, a3: C, a4: D) -> R in
            return map(property.value, a1, a2, a3, a4)
        }.observe { _ in }
    }

    /// Provides a feed for specified protocol method.
    ///
    /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
    public func feed<S, A, B, C, D, E, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B, C, D, E) -> R) -> Disposable {
        return signal(for: selector) { (_: PassthroughSubject<Void, Never>, a1: A, a2: B, a3: C, a4: D, a5: E) -> R in
            return map(property.value, a1, a2, a3, a4, a5)
        }.observe { _ in }
    }
}

extension NSObject {

    private struct AssociatedKeys {
        static var ProtocolProxies = "ProtocolProxies"
    }

    fileprivate var protocolProxies: [ProtocolProxyPropertyController: ProtocolProxy] {
        get {
            if let proxies = objc_getAssociatedObject(self, &AssociatedKeys.ProtocolProxies) as? [ProtocolProxyPropertyController: ProtocolProxy] {
                return proxies
            } else {
                let proxies = [ProtocolProxyPropertyController: ProtocolProxy]()
                objc_setAssociatedObject(self, &AssociatedKeys.ProtocolProxies, proxies as NSDictionary, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return proxies
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ProtocolProxies, newValue as NSDictionary, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension ReactiveExtensions where Base: NSObject {

    /// Creates a proxy object that conforms to a given protocol and injects itself as a delegate for a given selector.
    /// The object can then be used to intercept various delegate callbacks as signals.
    ///
    /// - warning: If the protocol has any required methods, you have to handle them by providing a signal, a feed or implement
    /// them in a class whose instance you set to `forwardTo` property of the returned proxy object.
    public func protocolProxy(for `protocol`: Protocol, selector: Selector) -> ProtocolProxy {
        let controller = SelectorProtocolProxyPropertyController(object: base, selector: selector)
        return protocolProxy(protocol: `protocol`, controller: controller)
    }

    /// Creates a proxy object that conforms to a given protocol and injects itself as a delegate for a given key path.
    /// The object can then be used to intercept various delegate callbacks as signals.
    ///
    /// Original delegate will be saved into a `forwardTo` property of the proxy object and any calls to methods not implemented by the proxy
    /// will be forwarded to the original delegate.
    ///
    /// - warning: If the protocol has any required methods, you have to handle them by providing a signal, a feed,
    /// implement them in the original delegate or implement them in a class whose instance you set to `forwardTo` property of the returned proxy object.
    public func protocolProxy<P>(for `protocol`: Protocol, keyPath: ReferenceWritableKeyPath<Base, P>) -> ProtocolProxy {
        let controller = KeyPathProtocolProxyPropertyController(object: base, keyPath: keyPath)
        return protocolProxy(protocol: `protocol`, controller: controller)
    }
    
    /// Creates a proxy object that conforms to a given protocol and injects itself as a delegate for a given key path.
    /// The object can then be used to intercept various delegate callbacks as signals.
    ///
    /// Original delegate will be saved into a `forwardTo` property of the proxy object and any calls to methods not implemented by the proxy
    /// will be forwarded to the original delegate.
    ///
    /// - warning: If the protocol has any required methods, you have to handle them by providing a signal, a feed,
    /// implement them in the original delegate or implement them in a class whose instance you set to `forwardTo` property of the returned proxy object.
    public func protocolProxy<P>(for `protocol`: Protocol, keyPath: ReferenceWritableKeyPath<Base, P?>) -> ProtocolProxy {
        let controller = OptionalKeyPathProtocolProxyPropertyController(object: base, keyPath: keyPath)
        return protocolProxy(protocol: `protocol`, controller: controller)
    }

    public func hasProtocolProxy(for protocol: Protocol) -> Bool {
        return base.protocolProxies.values.first(where: { $0.protocol === `protocol` }) != nil
    }

    private func protocolProxy(protocol: Protocol, controller: ProtocolProxyPropertyController) -> ProtocolProxy {
        if let proxy = base.protocolProxies[controller] {
            return proxy
        } else {
            let proxy = ProtocolProxy(protocol: `protocol`, propertyController: controller)
            base.protocolProxies[controller] = proxy
            return proxy
        }
    }
}
