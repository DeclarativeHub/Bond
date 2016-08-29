//
//  NSObject+KVO.swift
//  Bond
//
//  Created by Srdan Rasic on 23/08/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import Foundation
import ReactiveKit

public extension NSObject {
  
  /// Create a signal that observes given key path using KVO.
  public func valueFor<T>(keyPath: String, sendInitial: Bool = true, retainStrongly: Bool = true) -> Signal<T, NoError> {
    return RKKeyValueSignal<T>(keyPath: keyPath, ofObject: self, sendInitial: sendInitial, retainStrongly: retainStrongly) { (object: Any?) -> T? in
      return object as? T
      }.toSignal()
  }
  
  /// Create a signal that observes given key path using KVO.
  public func valueFor<T: OptionalProtocol>(keyPath: String, sendInitial: Bool = true, retainStrongly: Bool = true) -> Signal<T, NoError> {
    return RKKeyValueSignal(keyPath: keyPath, ofObject: self, sendInitial: sendInitial, retainStrongly: retainStrongly) { (object: Any?) -> T? in
      if object == nil {
        return T(nilLiteral: ())
      } else {
        if let object = object as? T.Wrapped {
          return T(object)
        } else {
          return T(nilLiteral: ())
        }
      }
      }.toSignal()
  }
}

// MARK: - Implementations

fileprivate class RKKeyValueSignal<T>: NSObject, SignalProtocol {
  private var strongObject: NSObject? = nil
  private weak var object: NSObject? = nil
  private var context = 0
  private var keyPath: String
  private var options: NSKeyValueObservingOptions
  private let transform: @escaping (Any?) -> T?
  private let subject: AnySubject<T, NoError>
  private var numberOfObservers: Int = 0
  
  fileprivate init(keyPath: String, ofObject object: NSObject, sendInitial: Bool, retainStrongly: Bool, transform: @escaping (Any?) -> T?) {
    self.keyPath = keyPath
    self.options = sendInitial ? NSKeyValueObservingOptions.new.union(.initial) : .new
    self.transform = transform
    
    if sendInitial {
      subject = AnySubject(base: ReplaySubject(bufferSize: 1))
    } else {
      subject = AnySubject(base: PublishSubject())
    }
    
    super.init()
    
    self.object = object
    if retainStrongly {
      self.strongObject = object
    }
  }
  
  deinit {
    subject.completed()
    print("deinit")
  }
  
  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if context == &self.context {
      if let newValue = change?[NSKeyValueChangeKey.newKey] {
        if let newValue = transform(newValue) {
          subject.next(newValue)
        } else {
          fatalError("Value [\(newValue)] not convertible to \(T.self) type!")
        }
      } else {
        // no new value - ignore
      }
    } else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }
  
  private func increaseNumberOfObservers() {
    numberOfObservers += 1
    if numberOfObservers == 1 {
      object?.addObserver(self, forKeyPath: keyPath, options: options, context: &self.context)
    }
  }
  
  private func decreaseNumberOfObservers() {
    numberOfObservers -= 1
    if numberOfObservers == 0 {
      object?.removeObserver(self, forKeyPath: self.keyPath)
    }
  }
  
  public func observe(with observer: @escaping (Event<T, NoError>) -> Void) -> Disposable {
    increaseNumberOfObservers()
    let disposable = subject.observe(with: observer)
    let cleanupDisposabe = BlockDisposable {
      disposable.dispose()
      self.decreaseNumberOfObservers()
    }
    return DeinitDisposable(disposable: cleanupDisposabe)
  }
}
