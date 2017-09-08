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

public extension NSObject {

  /// KVO reactive extensions error.
  public enum KVOError: Error {

    /// Sent when the type is not convertible to the expected type.
    case notConvertible(String)
  }
}

public extension ReactiveExtensions where Base: NSObject {

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
  public func keyPath<T>(_ keyPath: String, ofExpectedType: T.Type, context: ExecutionContext) -> DynamicSubject2<T, NSObject.KVOError> {
    return DynamicSubject2(
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
  public func keyPath<T>(_ keyPath: String, ofExpectedType: T.Type, context: ExecutionContext) -> DynamicSubject2<T, NSObject.KVOError> where T: OptionalProtocol {
    return DynamicSubject2(
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

public extension ReactiveExtensions where Base: NSObject, Base: BindingExecutionContextProvider {

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
  public func keyPath<T>(_ keyPath: String, ofExpectedType: T.Type) -> DynamicSubject2<T, NSObject.KVOError> {
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
  public func keyPath<T>(_ keyPath: String, ofExpectedType: T.Type) -> DynamicSubject2<T, NSObject.KVOError> where T: OptionalProtocol {
    return self.keyPath(keyPath, ofExpectedType: ofExpectedType, context: base.bindingExecutionContext)
  }
}

// MARK: - Implementation

private class RKKeyValueSignal: NSObject, SignalProtocol {
  private weak var object: NSObject? = nil
  private var context = 0
  private var keyPath: String
  private let subject: Subject<Void, NoError>
  private var numberOfObservers: Int = 0
  private var observing = false
  private let deallocationDisposable = SerialDisposable(otherDisposable: nil)
  private let lock = NSRecursiveLock(name: "com.reactivekit.bond.rkkeyvaluesignal")
  
  fileprivate init(keyPath: String, for object: NSObject) {
    self.keyPath = keyPath
    self.subject = PublishSubject()
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
    subject.completed()
  }
  
  fileprivate override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if context == &self.context {
      if let _ = change?[NSKeyValueChangeKey.newKey] {
        subject.next(())
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

  fileprivate func observe(with observer: @escaping (Event<Void, NoError>) -> Void) -> Disposable {
    increaseNumberOfObservers()
    let disposable = subject.observe(with: observer)
    let cleanupDisposabe = BlockDisposable {
      disposable.dispose()
      self.decreaseNumberOfObservers()
    }
    return DeinitDisposable(disposable: cleanupDisposabe)
  }
}

extension NSObject {

  private struct StaticVariables {
    static var willDeallocateSubject = "WillDeallocateSubject"
    static var swizzledTypes: Set<String> = []
    static var lock = NSRecursiveLock(name: "com.reactivekit.bond.nsobject")
  }

  fileprivate var _willDeallocate: Signal<UnownedUnsafe<NSObject>, NoError> {
    StaticVariables.lock.lock(); defer { StaticVariables.lock.unlock() }
    if let subject = objc_getAssociatedObject(self, &StaticVariables.willDeallocateSubject) as? ReplayOneSubject<UnownedUnsafe<NSObject>, NoError> {
      return subject.toSignal()
    } else {
      let subject = ReplayOneSubject<UnownedUnsafe<NSObject>, NoError>()
      subject.next(UnownedUnsafe(self))
      let typeName = String(describing: type(of: self))

      if !StaticVariables.swizzledTypes.contains(typeName) {
        StaticVariables.swizzledTypes.insert(typeName)
        type(of: self)._swizzleDeinit { me in
          if let subject = objc_getAssociatedObject(me, &StaticVariables.willDeallocateSubject) as? ReplayOneSubject<UnownedUnsafe<NSObject>, NoError> {
            subject.completed()
          }
        }
      }

      objc_setAssociatedObject(self, &StaticVariables.willDeallocateSubject, subject, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return subject.toSignal()
    }
  }

  private class func _swizzleDeinit(onDeinit: @escaping (NSObject) -> Void) {
    let selector = sel_registerName("dealloc")
    var originalImplementation: IMP? = nil

    let swizzledImplementationBlock: @convention(block) (UnsafeRawPointer) -> Void = { me in
      onDeinit(unsafeBitCast(me, to: NSObject.self))
      let superImplementation = class_getMethodImplementation(class_getSuperclass(self), selector)
      if let imp = originalImplementation ?? superImplementation {
        typealias _IMP = @convention(c) (UnsafeRawPointer, Selector) -> Void
        unsafeBitCast(imp, to: _IMP.self)(me, selector)
      }
    }

    let swizzledImplementation = imp_implementationWithBlock(swizzledImplementationBlock)

    if !class_addMethod(self, selector, swizzledImplementation, "v@:"), let method = class_getInstanceMethod(self, selector) {
      originalImplementation = method_getImplementation(method)
      originalImplementation = method_setImplementation(method, swizzledImplementation)
    }
  }
}

fileprivate struct UnownedUnsafe<T: AnyObject> {
  unowned(unsafe) let unbox: T
  init(_ value: T) { unbox = value }
}
