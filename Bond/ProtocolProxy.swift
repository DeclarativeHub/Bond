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

public typealias ArgumentExtractor = (Int, UnsafeMutableRawPointer?) -> Void
public typealias ReturnValueSetter = (UnsafeMutableRawPointer?) -> Void

fileprivate func arg<T>(_ extractor: ArgumentExtractor, _ pos: Int) -> T {
  let arg = UnsafeMutablePointer<T>.allocate(capacity: 1)
  extractor(pos, arg)
  return arg.pointee
}

public class ProtocolProxy: BNDProtocolProxyBase {

  private var invokers: [Selector: (ArgumentExtractor, ReturnValueSetter?) -> Void] = [:]
  private var handlers: [Selector: AnyObject] = [:]
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

  public override func invoke(with selector: Selector, argumentExtractor: @escaping ArgumentExtractor, setReturnValue: ReturnValueSetter?) {
    guard let invoker = invokers[selector] else { return }
    invoker(argumentExtractor, setReturnValue)
  }

  private func registerInvoker<R>(for selector: Selector, block: @escaping () -> R) {
    invokers[selector] = { _, setReturnValue in
      var r = block()
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func registerInvoker<T, R>(for selector: Selector, block: @escaping (T) -> R) {
    invokers[selector] = { extractor, setReturnValue in
      var r = block(arg(extractor, 2))
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func registerInvoker<T, U, R>(for selector: Selector, block: @escaping (T, U) -> R) {
    invokers[selector] = { extractor, setReturnValue in
      var r = block(arg(extractor, 2), arg(extractor, 3))
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func registerInvoker<T, U, V, R>(for selector: Selector, block: @escaping (T, U, V) -> R) {
    invokers[selector] = { extractor, setReturnValue in
      var r = block(arg(extractor, 2), arg(extractor, 3), arg(extractor, 4))
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func registerInvoker<T, U, V, W, R>(for selector: Selector, block: @escaping (T, U, V, W) -> R) {
    invokers[selector] = { extractor, setReturnValue in
      var r = block(arg(extractor, 2), arg(extractor, 3), arg(extractor, 4), arg(extractor, 5))
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func registerInvoker<T, U, V, W, X, R>(for selector: Selector, block: @escaping (T, U, V, W, X) -> R) {
    invokers[selector] = { extractor, setReturnValue in
      var r = block(arg(extractor, 2), arg(extractor, 3), arg(extractor, 4), arg(extractor, 5), arg(extractor, 6))
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func _signal<S>(for selector: Selector, registerInvoker: (PublishSubject1<S>) -> Void) -> Signal1<S>{
    if let signal = handlers[selector] {
      return (signal as! PublishSubject1<S>).toSignal()
    } else {
      let subject = PublishSubject1<S>()
      handlers[selector] = subject
      registerInvoker(subject)
      return subject.toSignal()
    }
  }

  /// Maps the given protocol method to a signal. Whenever the method on the target object is called,
  /// the framework will call the provided `dispatch` closure that you can use to generate a signal.
  ///
  /// - parameter selector: Selector of the method to map.
  /// - parameter dispatch: A closure that dispatches calls to the given PublishSubject.
  public func signal<S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>) -> R) -> Signal1<S> {
    return _signal(for: selector) { subject in
      registerInvoker(for: selector) { () -> R in
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
  public func signal<A, S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>, A) -> R) -> Signal1<S> {
    return _signal(for: selector) { subject in
      registerInvoker(for: selector) { (a: A) -> R in
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
  public func signal<A, B, S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>, A, B) -> R) -> Signal1<S> {
    return _signal(for: selector) { subject in
      registerInvoker(for: selector) { (a: A, b: B) -> R in
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
  public func signal<A, B, C, S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>, A, B, C) -> R) -> Signal1<S> {
    return _signal(for: selector) { subject in
      registerInvoker(for: selector) { (a: A, b: B, c: C) -> R in
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
  public func signal<A, B, C, D, S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>, A, B, C, D) -> R) -> Signal1<S> {
    return _signal(for: selector) { subject in
      registerInvoker(for: selector) { (a: A, b: B, c: C, d: D) -> R in
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
  public func signal<A, B, C, D, E, S, R>(for selector: Selector, dispatch: @escaping (PublishSubject<S, NoError>, A, B, C, D, E) -> R) -> Signal1<S> {
    return _signal(for: selector) { subject in
      registerInvoker(for: selector) { (a: A, b: B, c: C, d: D, e: E) -> R in
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
    if handlers[aSelector] != nil {
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
  public func feed<S, A, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A) -> R) {
    let _ = signal(for: selector) { (_: PublishSubject<Void, NoError>, a1: A) -> R in
      return map(property.value, a1)
    }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<S, A, B, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B) -> R) {
    let _ = signal(for: selector) { (_: PublishSubject<Void, NoError>, a1: A, a2: B) -> R in
      return map(property.value, a1, a2)
    }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<S, A, B, C, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B, C) -> R) {
    let _ = signal(for: selector) { (_: PublishSubject<Void, NoError>, a1: A, a2: B, a3: C) -> R in
      return map(property.value, a1, a2, a3)
    }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<S, A, B, C, D, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B, C, D) -> R) {
    let _ = signal(for: selector) { (_: PublishSubject<Void, NoError>, a1: A, a2: B, a3: C, a4: D) -> R in
      return map(property.value, a1, a2, a3, a4)
    }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<S, A, B, C, D, E, R>(property: Property<S>, to selector: Selector, map: @escaping (S, A, B, C, D, E) -> R) {
    let _ = signal(for: selector) { (_: PublishSubject<Void, NoError>, a1: A, a2: B, a3: C, a4: D, a5: E) -> R in
      return map(property.value, a1, a2, a3, a4, a5)
    }
  }
}
