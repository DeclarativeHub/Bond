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

private extension BNDInvocation {

 func readArgument<T>(_ index: Int) -> T {
    let size = Int(methodSignature.getArgumentSize(at: UInt(index)))
    let alignment = Int(methodSignature.getArgumentAlignment(at: UInt(index)))

    let pointer = UnsafeMutableRawPointer.allocate(bytes: size, alignedTo: alignment)
    getArgument(pointer, at: index)

    let type = methodSignature.getArgumentType(at: UInt(index))
    switch type {
    case NSObjCCharType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CChar.self).pointee) as! T
    case NSObjCShortType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CShort.self).pointee) as! T
    case NSObjCIntType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CInt.self).pointee) as! T
    case NSObjCLongType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CLong.self).pointee) as! T
    case NSObjCLonglongType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CLongLong.self).pointee) as! T
    case NSObjCUCharType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CUnsignedChar.self).pointee) as! T
    case NSObjCUShortType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CUnsignedShort.self).pointee) as! T
    case NSObjCUIntType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CUnsignedInt.self).pointee) as! T
    case NSObjCULongType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CUnsignedLong.self).pointee) as! T
    case NSObjCULonglongType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CUnsignedLongLong.self).pointee) as! T
    case NSObjCFloatType:
     return NSNumber(value: pointer.assumingMemoryBound(to: CFloat.self).pointee) as! T
    case NSObjCDoubleType:
     return NSNumber(value: pointer.assumingMemoryBound(to: CDouble.self).pointee) as! T
    case NSObjCBoolType:
      return NSNumber(value: pointer.assumingMemoryBound(to: CBool.self).pointee) as! T
    case NSObjCSelectorType:
      return pointer.assumingMemoryBound(to: Optional<Selector>.self).pointee as! T
    case NSObjCObjectType:
      return pointer.assumingMemoryBound(to: Optional<AnyObject>.self).pointee as! T
    default:
      fatalError("Bridging ObjC type `\(type)` is not supported.")
    }

    pointer.deallocate(bytes: size, alignedTo: alignment)
  }

 func writeReturnValue<T>(_ value: T) {
    guard methodSignature.methodReturnLength > 0 else { return }

    let size = methodSignature.getReturnArgumentSize()
    let alignment = methodSignature.getReturnArgumentAlignment()
    let type = methodSignature.getReturnArgumentType()

  func write<U, V>(_ value: V, as type: U.Type) {
      let pointer = UnsafeMutablePointer<U>.allocate(capacity: 1)
      pointer.initialize(to: value as! U, count: 1)
      setReturnValue(pointer)
      pointer.deallocate(capacity: 1)
    }

    switch type {
    case NSObjCCharType:
      write(value as! NSNumber, as: CChar.self)
    case NSObjCShortType:
      write(value as! NSNumber, as: CShort.self)
    case NSObjCIntType:
      write(value as! NSNumber, as: CInt.self)
    case NSObjCLongType:
      write(value as! NSNumber, as: CLong.self)
    case NSObjCLonglongType:
      write(value as! NSNumber, as: CLongLong.self)
    case NSObjCUCharType:
      write(value as! NSNumber, as: CUnsignedChar.self)
    case NSObjCUShortType:
      write(value as! NSNumber, as: CUnsignedShort.self)
    case NSObjCUIntType:
      write(value as! NSNumber, as: CUnsignedInt.self)
    case NSObjCULongType:
      write(value as! NSNumber, as: CUnsignedLong.self)
    case NSObjCULonglongType:
      write(value as! NSNumber, as: CUnsignedLongLong.self)
    case NSObjCFloatType:
      write(value as! NSNumber, as: CFloat.self)
    case NSObjCDoubleType:
      write(value as! NSNumber, as: CDouble.self)
    case NSObjCBoolType:
      write(value as! NSNumber, as: CBool.self)
    case NSObjCSelectorType:
      write(value, as: Optional<Selector>.self)
    case NSObjCObjectType:
      write(value, as: Optional<AnyObject>.self)
    default:
      fatalError("Bridging ObjC type `\(type)` is not supported.")
    }
  }
}

public class ProtocolProxy: BNDProtocolProxyBase {

  private var invokers: [Selector: (BNDInvocation) -> Void] = [:]
  private var handlers: [Selector: Any] = [:]
  private weak var object: NSObject?
  private let setter: Selector

  public init(object: NSObject, `protocol`: Protocol, setter: Selector) {
    self.object = object
    self.setter = setter
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
    invoker(invocation)
  }

  private func registerInvoker0<R>(for selector: Selector, block: @escaping () -> R) -> Disposable {
    invokers[selector] = { invocation in
      let result = block()
      invocation.writeReturnValue(result)
    }
    registerDelegate()
    return BlockDisposable { [weak self] in
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
    return BlockDisposable { [weak self] in
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
    return BlockDisposable { [weak self] in
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
    return BlockDisposable { [weak self] in
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
    return BlockDisposable { [weak self] in
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
    return BlockDisposable { [weak self] in
      self?.invokers[selector] = nil
      self?.registerDelegate()
    }
  }

  private func _signal<S>(for selector: Selector, registerInvoker: @escaping (SafePublishSubject<S>) -> Disposable) -> SafeSignal<S>{
    if let signal = handlers[selector] {
      return signal as! SafeSignal<S>
    } else {
      let signal = SafeSignal<S> { [weak self] observer in
        let subject = SafePublishSubject<S>()
        let disposable = CompositeDisposable()
        disposable += registerInvoker(subject)
        disposable += subject.observe(with: observer)
        disposable += BlockDisposable { [weak self] in self?.handlers[selector] = nil }
        return disposable
      }.shareReplay(limit: 0)
      handlers[selector] = signal
      return signal
    }
  }

  /// Maps the given protocol method to a signal. Whenever the method on the target object is called,
  /// the framework will call the provided `dispatch` closure that you can use to generate a signal.
  ///
  /// - parameter selector: Selector of the method to map.
  /// - parameter dispatch: A closure that dispatches calls to the given PublishSubject.
  public func signal<S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>) -> R) -> SafeSignal<S> {
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
  /// - parameter dispatch: A closure that dispatches calls to the given PublishSubject.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
  /// in place of generic parameter A and R!
  public func signal<A, S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>, A) -> R) -> SafeSignal<S> {
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
  /// - parameter dispatch: A closure that dispatches calls to the given PublishSubject.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
  /// in place of generic parameters A, B and R!
  public func signal<A, B, S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>, A, B) -> R) -> SafeSignal<S> {
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
  /// - parameter dispatch: A closure that dispatches calls to the given PublishSubject.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
  /// in place of generic parameters A, B, C and R!
  public func signal<A, B, C, S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>, A, B, C) -> R) -> SafeSignal<S> {
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
  /// - parameter dispatch: A closure that dispatches calls to the given PublishSubject.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
  /// in place of generic parameters A, B, C, D and R!
  public func signal<A, B, C, D, S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>, A, B, C, D) -> R) -> SafeSignal<S> {
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
  /// - parameter dispatch: A closure that dispatches calls to the given PublishSubject.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
  /// in place of generic parameters A, B, C, D, E and R!
  public func signal<A, B, C, D, E, S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>, A, B, C, D, E) -> R) -> SafeSignal<S> {
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
    _ = object?.perform(setter, with: nil)
    _ = object?.perform(setter, with: self)
  }

  deinit {
    _ = object?.perform(setter, with: nil)
  }
}

extension NSObject {

  private struct AssociatedKeys {
    static var ProtocolProxies = "ProtocolProxies"
  }

  private var protocolProxies: [String: ProtocolProxy] {
    get {
      if let proxies = objc_getAssociatedObject(self, &AssociatedKeys.ProtocolProxies) as? [String: ProtocolProxy] {
        return proxies
      } else {
        let proxies = [String: ProtocolProxy]()
        objc_setAssociatedObject(self, &AssociatedKeys.ProtocolProxies, proxies as NSDictionary, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return proxies
      }
    }
    set {
      objc_setAssociatedObject(self, &AssociatedKeys.ProtocolProxies, newValue as NSDictionary, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  /// Registers and returns an object that will act as a delegate (or data source) for given protocol and setter method.
  ///
  /// For example, to register a table view delegate do: `tableView.protocolProxyFor(UITableViewDelegate.self, setter: NSSelectorFromString("setDelegate:"))`.
  ///
  /// Note that if the protocol has any required methods, you have to handle them by providing a signal, a feed or implement them in a class
  /// whose instance you'll set to `forwardTo` property.
  public func protocolProxy(for `protocol`: Protocol, setter: Selector) -> ProtocolProxy {
    let key = String(cString: protocol_getName(`protocol`))
    if let proxy = protocolProxies[key] {
      return proxy
    } else {
      let proxy = ProtocolProxy(object: self, protocol: `protocol`, setter: setter)
      protocolProxies[key] = proxy
      return proxy
    }
  }
}

extension ProtocolProxy {

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<S, A, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A) -> R) -> Disposable {
    return signal(for: selector) { (_: PublishSubject<Void, NoError>, a1: A) -> R in
      return map(property.value, a1)
    }.observe { _ in }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<S, A, B, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B) -> R) -> Disposable {
    return signal(for: selector) { (_: PublishSubject<Void, NoError>, a1: A, a2: B) -> R in
      return map(property.value, a1, a2)
    }.observe { _ in }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<S, A, B, C, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B, C) -> R) -> Disposable {
    return signal(for: selector) { (_: PublishSubject<Void, NoError>, a1: A, a2: B, a3: C) -> R in
      return map(property.value, a1, a2, a3)
    }.observe { _ in }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<S, A, B, C, D, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B, C, D) -> R) -> Disposable {
    return signal(for: selector) { (_: PublishSubject<Void, NoError>, a1: A, a2: B, a3: C, a4: D) -> R in
      return map(property.value, a1, a2, a3, a4)
    }.observe { _ in }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<S, A, B, C, D, E, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B, C, D, E) -> R) -> Disposable {
    return signal(for: selector) { (_: PublishSubject<Void, NoError>, a1: A, a2: B, a3: C, a4: D, a5: E) -> R in
      return map(property.value, a1, a2, a3, a4, a5)
    }.observe { _ in }
  }
}
