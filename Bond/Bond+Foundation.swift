//
//  Bond+Foundation.swift
//  Bond
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

private var XXContext = 0

@objc private class DynamicKVOHelper: NSObject {

  let listener: AnyObject -> Void
  weak var object: NSObject?
  let keyPath: String
  
  init(keyPath: String, object: NSObject, listener: AnyObject -> Void) {
    self.keyPath = keyPath
    self.object = object
    self.listener = listener
    super.init()
    self.object?.addObserver(self, forKeyPath: keyPath, options: .New, context: &XXContext)
  }
  
  deinit {
    object?.removeObserver(self, forKeyPath: keyPath)
  }
  
  override dynamic func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
    if context == &XXContext {
      if let newValue: AnyObject = change[NSKeyValueChangeNewKey] {
        listener(newValue)
      }
    }
  }
}

@objc private class DynamicNotificationCenterHelper: NSObject {
  let listener: NSNotification -> Void
  
  init(notificationName: String, object: AnyObject?, listener: NSNotification -> Void) {
    self.listener = listener
    super.init()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveNotification:", name: notificationName, object: object)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  dynamic func didReceiveNotification(notification: NSNotification) {
    listener(notification)
  }
}

public func dynamicObservableFor<T>(object: NSObject, #keyPath: String, #defaultValue: T) -> Dynamic<T> {
  let keyPathValue: AnyObject? = object.valueForKeyPath(keyPath)
  let value: T = (keyPathValue != nil) ? (keyPathValue as? T)! : defaultValue
  let dynamic = InternalDynamic(value, faulty: false)
  
  let helper = DynamicKVOHelper(keyPath: keyPath, object: object as NSObject) {
    [unowned dynamic] (v: AnyObject) -> Void in
    
    if v is NSNull {
      dynamic.value = defaultValue
    } else {
      dynamic.value = (v as? T)!
    }
  }
  
  dynamic.retain(helper)
  return dynamic
}

public func dynamicObservableFor<T>(object: NSObject, #keyPath: String, #from: AnyObject? -> T, #to: T -> AnyObject?) -> Dynamic<T> {
  let keyPathValue: AnyObject? = object.valueForKeyPath(keyPath)
  let dynamic = InternalDynamic(from(keyPathValue), faulty: false)
  
  let helper = DynamicKVOHelper(keyPath: keyPath, object: object as NSObject) {
    [unowned dynamic] (v: AnyObject?) -> Void in
    dynamic.value = from(v)
  }
  
  let feedbackBond = Bond<T>() { [weak object] value in
    if let object = object {
      object.setValue(to(value) ?? NSNull(), forKey: keyPath)
    }
  }
  
  dynamic.bindTo(feedbackBond, fire: false, strongly: false)
  dynamic.retain(feedbackBond)
  
  dynamic.retain(helper)
  return dynamic
}

public func dynamicObservableFor<T>(notificationName: String, #object: AnyObject?, #parser: NSNotification -> T) -> InternalDynamic<T> {
  let dynamic: InternalDynamic<T> = InternalDynamic(parser(NSNotification(name: notificationName, object: nil)), faulty: true)
  
  let helper = DynamicNotificationCenterHelper(notificationName: notificationName, object: object) {
    [unowned dynamic] notification in
    dynamic.value = parser(notification)
  }
  
  dynamic.retain(helper)
  return dynamic
}


public extension Dynamic {
  public class func asObservableFor(object: NSObject, keyPath: String, defaultValue: T) -> Dynamic<T> {
    let dynamic: Dynamic<T> = dynamicObservableFor(object, keyPath: keyPath, defaultValue: defaultValue)
    return dynamic
  }
  
  public class func asObservableFor(notificationName: String, object: AnyObject?, parser: NSNotification -> T) -> Dynamic<T> {
    let dynamic: InternalDynamic<T> = dynamicObservableFor(notificationName, object: object, parser: parser)
    return dynamic
  }
}
