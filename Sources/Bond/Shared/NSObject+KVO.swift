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
import ReactiveKit

extension NSObject {

    /// KVO reactive extensions error.
    public enum KVOError: Error {

        /// Sent when the type is not convertible to the expected type.
        case notConvertible(String)
    }
}

extension ReactiveExtensions where Base: NSObject {

    /// Creates a signal that represents values of the given KVO-compatible key path.
    ///
    ///     class User: NSObject {
    ///         @objc dynamic var name: String
    ///         ...
    ///     }
    ///
    ///     ...
    ///
    ///     user.keyPath(\.name).bind(to: nameLabel)
    ///
    /// - Parameters:
    ///   - keyPath: Key path of the KVO-compatible property whose values should be represented as a signal.
    ///   - startWithCurrentValue: When set to true (default), the signal will start with the current value on the key path.
    ///
    /// - Warning: The disposable returned by observing the key path signal has to be retained as long
    ///            as the observaton is alive. Releasing the disposable will dispose the observation automatically.
    ///            The rule should be ignored if using bindings instead of observations.
    public func keyPath<T>(_ keyPath: KeyPath<Base, T>, startWithCurrentValue: Bool = true) -> SafeSignal<T> {
        return Signal { [weak base] observer in
            guard let base = base else { return NonDisposable.instance }

            let options: NSKeyValueObservingOptions = startWithCurrentValue ? [.initial] : []

            let subscription = base.observe(keyPath, options: options) { base, change in
                observer.receive(base[keyPath: keyPath])
            }

            let disposable = base._willDeallocate.observeCompleted {
                subscription.invalidate()
                observer.receive(completion: .finished)
            }

            return DeinitDisposable(disposable: MainBlockDisposable {
                  subscription.invalidate()
                  disposable.dispose()
            })
        }
    }
}

extension ReactiveExtensions where Base: NSObject {

    /// Creates a `DynamicSubject` representing the given KVO path of the given type.
    ///
    /// If the key path emits a value of type other than `ofType`, program execution will stop with `fatalError`.
    ///
    ///     user.keyPath("name", ofType: String.self, context: .immediateOnMain)
    ///
    /// - Parameters:
    ///   - keyPath: Key path of the property to wrap.
    ///   - ofType: Type of the property to wrap, e.g. `Int.self`.
    ///   - context: Execution context in which to update the property. Use `.immediateOnMain` to update the object from main queue.
    public func keyPath<T>(_ keyPath: String, ofType: T.Type, context: ExecutionContext) -> DynamicSubject<T> {
        return DynamicSubject(
            target: base,
            signal: RKKeyValueSignal(keyPath: keyPath, for: base).toSignal(),
            context: context,
            get: { (target) -> T in
                let maybeValue = target.value(forKeyPath: keyPath)
                if let value = maybeValue as? T {
                    return value
                } else {
                    fatalError("Could not convert \(String(describing: maybeValue)) to \(T.self). Use `keyPath(:ofExpectedType:)` to create a failing signal.)")
                }
            },
            set: {
                $0.setValue($1, forKeyPath: keyPath)
            },
            triggerEventOnSetting: false
        )
    }

    /// Creates a `DynamicSubject` representing the given KVO path of the given optional type.
    ///
    /// If the key path emits a value of type other than `ofType`, program execution will stop with `fatalError`.
    ///
    ///     user.keyPath("name", ofType: Optional<String>.self, context: .immediateOnMain)
    ///
    /// - Parameters:
    ///   - keyPath: Key path of the property to wrap.
    ///   - ofType: Type of the property to wrap, e.g. `Optional<Int>.self`.
    ///   - context: Execution context in which to update the property. Use `.immediateOnMain` to update the object from main queue.
    public func keyPath<T>(_ keyPath: String, ofType: T.Type, context: ExecutionContext) -> DynamicSubject<T> where T: OptionalProtocol {
        return DynamicSubject(
            target: base,
            signal: RKKeyValueSignal(keyPath: keyPath, for: base).toSignal(),
            context: context,
            get: { (target) -> T in
                let maybeValue = target.value(forKeyPath: keyPath)
                if let value = maybeValue as? T {
                    return value
                } else if maybeValue == nil {
                    return T(nilLiteral: ())
                } else {
                    fatalError("Could not convert \(String(describing: maybeValue)) to \(T.self). Use `keyPath(:ofExpectedType:)` to create a failing signal.")
                }
            },
            set: {
                if let value = $1._unbox {
                    $0.setValue(value, forKeyPath: keyPath)
                } else {
                    $0.setValue(nil, forKeyPath: keyPath)
                }
            },
            triggerEventOnSetting: false
        )
    }

    /// Creates a `DynamicSubject` representing the given KVO path of the given expected type.
    ///
    /// If the key path emits a value of type other than `ofExpectedType`, the subject will fail with a `KVOError`.
    ///
    ///     user.keyPath("name", ofExpectedType: String.self, context: .immediateOnMain)
    ///
    /// - Parameters:
    ///   - keyPath: Key path of the property to wrap.
    ///   - ofExpectedType: Type of the property to wrap, e.g. `Int.self`.
    ///   - context: Execution context in which to update the property. Use `.immediateOnMain` to update the object from main queue.
    public func keyPath<T>(_ keyPath: String, ofExpectedType: T.Type, context: ExecutionContext) -> FailableDynamicSubject<T, NSObject.KVOError> {
        return FailableDynamicSubject(
            target: base,
            signal: RKKeyValueSignal(keyPath: keyPath, for: base).castError(),
            context: context,
            get: { (target) -> Result<T, NSObject.KVOError> in
                let maybeValue = target.value(forKeyPath: keyPath)
                if let value = maybeValue as? T {
                    return .success(value)
                } else {
                    return .failure(.notConvertible("Could not convert \(String(describing: maybeValue)) to \(T.self)."))
                }
            },
            set: {
                $0.setValue($1, forKeyPath: keyPath)
            },
            triggerEventOnSetting: false
        )
    }

    /// Creates a `DynamicSubject` representing the given KVO path of the given expected type.
    ///
    /// If the key path emits a value of type other than `ofExpectedType`, the subject will fail with a `KVOError`.
    ///
    ///     user.keyPath("name", ofExpectedType: Optional<String>.self, context: .immediateOnMain)
    ///
    /// - Parameters:
    ///   - keyPath: Key path of the property to wrap.
    ///   - ofExpectedType: Type of the property to wrap, e.g. `Optional<Int>.self`.
    ///   - context: Execution context in which to update the property. Use `.immediateOnMain` to update the object from main queue.
    public func keyPath<T>(_ keyPath: String, ofExpectedType: T.Type, context: ExecutionContext) -> FailableDynamicSubject<T, NSObject.KVOError> where T: OptionalProtocol {
        return FailableDynamicSubject(
            target: base,
            signal: RKKeyValueSignal(keyPath: keyPath, for: base).castError(),
            context: context,
            get: { (target) -> Result<T, NSObject.KVOError> in
                let maybeValue = target.value(forKeyPath: keyPath)
                if let value = maybeValue as? T {
                    return .success(value)
                } else if maybeValue == nil {
                    return .success(T(nilLiteral: ()))
                } else {
                    return .failure(.notConvertible("Could not convert \(String(describing: maybeValue)) to \(T.self)."))
                }
            },
            set: {
                if let value = $1._unbox {
                    $0.setValue(value, forKeyPath: keyPath)
                } else {
                    $0.setValue(nil, forKeyPath: keyPath)
                }
            },
            triggerEventOnSetting: false
        )
    }
}

extension ReactiveExtensions where Base: NSObject, Base: BindingExecutionContextProvider {

    /// Creates a `DynamicSubject` representing the given KVO path of the given type.
    ///
    ///     user.keyPath("name", ofType: String.self)
    ///
    /// - Parameters:
    ///   - keyPath: Key path of the property to wrap.
    ///   - ofType: Type of the property to wrap, e.g. `Int.self`.
    public func keyPath<T>(_ keyPath: String, ofType: T.Type) -> DynamicSubject<T> {
        return self.keyPath(keyPath, ofType: ofType, context: base.bindingExecutionContext)
    }

    /// Creates a `DynamicSubject` representing the given KVO path of the given optional type.
    ///
    ///     user.keyPath("name", ofType: Optional<String>.self)
    ///
    /// - Parameters:
    ///   - keyPath: Key path of the property to wrap.
    ///   - ofType: Type of the property to wrap, e.g. `Optional<Int>.self`.
    public func keyPath<T>(_ keyPath: String, ofType: T.Type) -> DynamicSubject<T> where T: OptionalProtocol {
        return self.keyPath(keyPath, ofType: ofType, context: base.bindingExecutionContext)
    }

    /// Creates a `DynamicSubject` representing the given KVO path of the given expected type.
    ///
    /// If the key path emits a value of type other than `ofExpectedType`, the subject will fail with a `KVOError`.
    ///
    ///     user.keyPath("name", ofExpectedType: String.self)
    ///
    /// - Parameters:
    ///   - keyPath: Key path of the property to wrap.
    ///   - ofExpectedType: Type of the property to wrap, e.g. `Int.self`.
    public func keyPath<T>(_ keyPath: String, ofExpectedType: T.Type) -> FailableDynamicSubject<T, NSObject.KVOError> {
        return self.keyPath(keyPath, ofExpectedType: ofExpectedType, context: base.bindingExecutionContext)
    }

    /// Creates a `DynamicSubject` representing the given KVO path of the given expected type.
    ///
    /// If the key path emits a value of type other than `ofExpectedType`, the subject will fail with a `KVOError`.
    ///
    ///     user.keyPath("name", ofExpectedType: Optional<String>.self)
    ///
    /// - Parameters:
    ///   - keyPath: Key path of the property to wrap.
    ///   - ofExpectedType: Type of the property to wrap, e.g. `Optional<Int>.self`.
    public func keyPath<T>(_ keyPath: String, ofExpectedType: T.Type) -> FailableDynamicSubject<T, NSObject.KVOError> where T: OptionalProtocol {
        return self.keyPath(keyPath, ofExpectedType: ofExpectedType, context: base.bindingExecutionContext)
    }
}

// MARK: - Implementation

private class RKKeyValueSignal: NSObject, SignalProtocol {
    private weak var object: NSObject? = nil
    private var context = 0
    private var keyPath: String
    private let subject: Subject<Void, Never>
    private var numberOfObservers: Int = 0
    private var observing = false
    private let deallocationDisposable = SerialDisposable(otherDisposable: nil)
    private let lock = NSRecursiveLock(name: "com.reactivekit.bond.rkkeyvaluesignal")

    fileprivate init(keyPath: String, for object: NSObject) {
        self.keyPath = keyPath
        self.subject = PassthroughSubject()
        self.object = object
        super.init()

        lock.lock()
        deallocationDisposable.otherDisposable = object._willDeallocate.reduce(nil, {$1}).observeNext { object in
            if self.observing {
                object?.unbox.removeObserver(self, forKeyPath: self.keyPath, context: &self.context)
            }
        }
        lock.unlock()
    }

    deinit {
        deallocationDisposable.dispose()
        subject.send(completion: .finished)
    }

    fileprivate override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &self.context {
            if let _ = change?[NSKeyValueChangeKey.newKey] {
                subject.send(())
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func increaseNumberOfObservers() {
        lock.lock(); defer { lock.unlock() }
        numberOfObservers += 1
        if let object = object, numberOfObservers == 1 && !observing {
            observing = true
            object.addObserver(self, forKeyPath: keyPath, options: [.new], context: &self.context)
        }
    }

    private func decreaseNumberOfObservers() {
        lock.lock(); defer { lock.unlock() }
        numberOfObservers -= 1
        if let object = object, numberOfObservers == 0 && observing {
            observing = false
            object.removeObserver(self, forKeyPath: self.keyPath, context: &self.context)
        }
    }

    fileprivate func observe(with observer: @escaping (Signal<Void, Never>.Event) -> Void) -> Disposable {
        increaseNumberOfObservers()
        let disposable = subject.observe(with: observer)
        let cleanupDisposabe = BlockDisposable {
            disposable.dispose()
            self.decreaseNumberOfObservers()
        }
        return DeinitDisposable(disposable: cleanupDisposabe)
    }
}
