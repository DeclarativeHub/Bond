//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
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

public extension NSObject {
  
  private struct AssociatedKeys {
    static var DisposeBagKey = "bnd_DisposeBagKey"
    static var AssociatedObservablesKey = "bnd_AssociatedObservablesKey"
  }
  
  // A dispose bag will will dispose upon object deinit.
  public var bnd_bag: DisposeBag {
    if let disposeBag: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.DisposeBagKey) {
      return disposeBag as! DisposeBag
    } else {
      let disposeBag = DisposeBag()
      objc_setAssociatedObject(self, &AssociatedKeys.DisposeBagKey, disposeBag, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return disposeBag
    }
  }
}

@objc private class BNDKVOObserver: NSObject {
  
  static private var XXContext = 0
  
  var object: NSObject
  let keyPath: String
  let listener: AnyObject? -> Void
  
  init(object: NSObject, keyPath: String, options: NSKeyValueObservingOptions, listener: AnyObject? -> Void) {
    self.object = object
    self.keyPath = keyPath
    self.listener = listener
    super.init()
    self.object.addObserver(self, forKeyPath: keyPath, options: options, context: &BNDKVOObserver.XXContext)
  }
  
  func set(value: AnyObject?) {
    object.setValue(value, forKey: keyPath)
  }
  
  deinit {
    object.removeObserver(self, forKeyPath: keyPath)
  }
  
  override dynamic func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if context == &BNDKVOObserver.XXContext {
      if let newValue: AnyObject? = change?[NSKeyValueChangeNewKey] {
        listener(newValue)
      }
    }
  }
}

public extension Observable {
  
  public convenience init(object: NSObject, keyPath: String) {
    
    if let value = object.valueForKeyPath(keyPath) as? Wrapped {
      self.init(value)
    } else {
      fatalError("Dear Sir/Madam, you are creating a Scalar of non-optional \(EventType.self) type, but the value at the given key path is nil or not of \(EventType.self) type. Please check the type or have your Scalar encapsulate optional type like Scalar<\(EventType.self)?>.")
    }
    
    var updatingFromSelf = false
    
    let observer = BNDKVOObserver(object: object, keyPath: keyPath, options: .New) { [weak self] value in
      updatingFromSelf = true
      if let value = value as? EventType {
        self?.value = value
      } else {
        fatalError("Dear Sir/Madam, it appears that the observed key path can hold nil values or values of type different than \(EventType.self). Please check the type or have your Scalar encapsulate optional type like Scalar<\(EventType.self)?>.")
      }
      updatingFromSelf = false
    }
    
    observeNew { value in
      if !updatingFromSelf {
        observer.set(value as? AnyObject)
      }
    }
  }
}

public extension Observable where Wrapped: OptionalType {
  
  public convenience init(object: NSObject, keyPath: String) {
    
    let initialValue: Wrapped.WrappedType?
    if let value = object.valueForKeyPath(keyPath) as? Wrapped.WrappedType {
      initialValue = value
    } else {
      initialValue = nil
    }
    
    self.init(EventType(optional: initialValue))
    
    var updatingFromSelf = false
    
    let observer = BNDKVOObserver(object: object, keyPath: keyPath, options: .New) { [weak self] value in
      updatingFromSelf = true
      if let value = value as? EventType.WrappedType {
        self?.value = EventType(optional: value)
      } else {
        self?.value = EventType(optional: nil)
      }
      updatingFromSelf = false
    }
    
    observeNew { value in
      if !updatingFromSelf {
        observer.set(value.value as? AnyObject)
      }
    }
  }
}

public extension NSObject {
  
  internal var bnd_associatedObservables: [String:AnyObject] {
    get {
      return objc_getAssociatedObject(self, &AssociatedKeys.AssociatedObservablesKey) as? [String:AnyObject] ?? [:]
    }
    set(observable) {
      objc_setAssociatedObject(self, &AssociatedKeys.AssociatedObservablesKey, observable, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  public func bnd_associatedObservableForValueForKey<T>(key: String, initial: T? = nil, set: (T -> Void)? = nil) -> Observable<T> {
    if let observable: AnyObject = bnd_associatedObservables[key] {
      return observable as! Observable<T>
    } else {
      let observable = Observable<T>(initial ?? self.valueForKey(key) as! T)
      bnd_associatedObservables[key] = observable
      
      observable
        .observeNew { [weak self] (value: T) in
          if let set = set {
            set(value)
          } else {
            if let value = value as? AnyObject {
              self?.setValue(value, forKey: key)
            } else {
              self?.setValue(nil, forKey: key)
            }
          }
        }
      
      return observable
    }
  }
  
  public func bnd_associatedObservableForValueForKey<T: OptionalType>(key: String, initial: T? = nil, set: (T -> Void)? = nil) -> Observable<T> {
    if let observable: AnyObject = bnd_associatedObservables[key] {
      return observable as! Observable<T>
    } else {
      let observable: Observable<T>
      if let initial = initial {
        observable = Observable(initial)
      } else if let value = self.valueForKey(key) as? T.WrappedType {
        observable = Observable(T(optional: value))
      } else {
        observable = Observable(T(optional: nil))
      }
      
      bnd_associatedObservables[key] = observable
      
      observable
        .observeNew { [weak self] (value: T) in
          if let set = set {
            set(value)
          } else {
            self?.setValue(value.value as! AnyObject?, forKey: key)
          }
        }
      
      return observable
    }
  }
}
