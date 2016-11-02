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

  public enum KVOError: Error {
    case notConvertible(String)
  }

  /// Returns a ```DynamicSubject``` representing the given KVO path of the given type.
  ///
  /// E.g. ```user.dynamic(keyPath: "name", ofType: String.self)```
  ///
  public func dynamic<T>(keyPath: String, ofType: T.Type) -> DynamicSubject<NSObject, T> {
    return DynamicSubject(
      target: self,
      signal: RKKeyValueSignal(keyPath: keyPath, for: self).toSignal(),
      get: { (target) -> T in
        let maybeValue = target.value(forKeyPath: keyPath)
        if let value = maybeValue as? T {
          return value
        } else {
          fatalError("Could not convert \(maybeValue) to \(T.self). Maybe `dynamic(keyPath:ofExpectedType:)` method might be of help?)")
        }
      },
      set: {
        $0.setValue($1, forKeyPath: keyPath)
      },
      triggerEventOnSetting: false
    )
  }

  /// Returns a ```DynamicSubject``` representing the given KVO path of the given type.
  ///
  /// E.g. ```user.dynamic(keyPath: "name", ofType: Optional<String>.self)```
  ///
  public func dynamic<T>(keyPath: String, ofType: T.Type) -> DynamicSubject<NSObject, T> where T: OptionalProtocol {
    return DynamicSubject(
      target: self,
      signal: RKKeyValueSignal(keyPath: keyPath, for: self).toSignal(),
      get: { (target) -> T in
        let maybeValue = target.value(forKeyPath: keyPath)
        if let value = maybeValue as? T {
          return value
        } else if maybeValue == nil {
          return T(nilLiteral: ())
        } else {
          fatalError("Could not convert \(maybeValue) to \(T.self). Maybe `dynamic(keyPath:ofExpectedType:)` method might be of help?)")
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

  /// Returns a ```DynamicSubject``` representing the given KVO path of the given expected type.
  ///
  /// If the key path emits a value other than ```ofExpectedType```, the subject will fail with a ```KVOError```.
  ///
  /// E.g. ```user.dynamic(keyPath: "name", ofType: String.self)```
  ///
  public func dynamic<T>(keyPath: String, ofExpectedType: T.Type) -> DynamicSubject2<NSObject, T, KVOError> {
    return DynamicSubject2(
      target: self,
      signal: RKKeyValueSignal(keyPath: keyPath, for: self).castError(),
      get: { (target) -> Result<T, KVOError> in
        let maybeValue = target.value(forKeyPath: keyPath)
        if let value = maybeValue as? T {
          return .success(value)
        } else {
          return .failure(.notConvertible("Could not convert \(maybeValue) to \(T.self)."))
        }
      },
      set: {
        $0.setValue($1, forKeyPath: keyPath)
      },
      triggerEventOnSetting: false
    )
  }

  /// Returns a ```DynamicSubject``` representing the given KVO path of the given expected type.
  ///
  /// If the key path emits a value other than ```ofExpectedType```, the subject will fail with a ```KVOError```.
  ///
  /// E.g. ```user.dynamic(keyPath: "name", ofType: Optional<String>.self)```
  ///
  public func dynamic<T>(keyPath: String, ofExpectedType: T.Type) -> DynamicSubject2<NSObject, T, KVOError> where T: OptionalProtocol {
    return DynamicSubject2(
      target: self,
      signal: RKKeyValueSignal(keyPath: keyPath, for: self).castError(),
      get: { (target) -> Result<T, KVOError> in
        let maybeValue = target.value(forKeyPath: keyPath)
        if let value = maybeValue as? T {
          return .success(value)
        } else if maybeValue == nil {
          return .success(T(nilLiteral: ()))
        } else {
          return .failure(.notConvertible("Could not convert \(maybeValue) to \(T.self)."))
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

// MARK: - Implementation

private class RKKeyValueSignal: NSObject, SignalProtocol {
  private weak var object: NSObject? = nil
  private var context = 0
  private var keyPath: String
  private let subject: AnySubject<Void, NoError>
  private var numberOfObservers: Int = 0
  private var observing = false
  private let deallocationDisposable = SerialDisposable(otherDisposable: nil)
  private let lock = NSRecursiveLock(name: "com.reactivekit.bond.rkkeyvaluesignal")
  
  fileprivate init(keyPath: String, for object: NSObject) {
    self.keyPath = keyPath
    self.subject = AnySubject(base: PublishSubject())
    self.object = object
    super.init()

    lock.lock()
    deallocationDisposable.otherDisposable = object._willDeallocate.observeNext { object in
      if self.observing {
        object.removeObserver(self, forKeyPath: self.keyPath, context: &self.context)
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
        subject.next()
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

  private var _willDeallocateSubject: ReplayOneSubject<NSObject, NoError>? {
    return objc_getAssociatedObject(self, &StaticVariables.willDeallocateSubject) as? ReplayOneSubject<NSObject, NoError>
  }

  fileprivate var _willDeallocate: Signal<NSObject, NoError> {
    StaticVariables.lock.lock(); defer { StaticVariables.lock.unlock() }
    if let subject = _willDeallocateSubject {
      return subject.toSignal()
    } else {
      let typeName: String = String(describing: type(of: self))

      if !StaticVariables.swizzledTypes.contains(typeName) {
        type(of: self)._swizzleDeinit()
        StaticVariables.swizzledTypes.insert(typeName)
      }

      let subject = ReplayOneSubject<NSObject, NoError>()
      objc_setAssociatedObject(self, &StaticVariables.willDeallocateSubject, subject, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)

      return subject.toSignal()
    }
  }

  private class func _swizzleDeinit() {
    let originalSelector = sel_getUid("dealloc")
    let swizzledSelector = NSSelectorFromString("_bnd_dealloc")

    let originalMethod = class_getInstanceMethod(self, originalSelector)
    let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)

    let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))

    if didAddMethod {
      class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod)
    }
  }

  @objc fileprivate func _bnd_swift_dealloc() {
    _willDeallocateSubject?.next(self)
    _willDeallocateSubject?.completed()
  }
}
