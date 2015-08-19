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
  
  internal func bnd_associatedObservableForValueForKey<T>(key: String, inout associationKey: String) -> Observable<T> {
    if let observable: AnyObject = objc_getAssociatedObject(self, &associationKey) {
      return observable as! Observable<T>
    } else {
      let observable = Observable<T>(self.valueForKey(key) as! T)
      objc_setAssociatedObject(self, &associationKey, observable, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      observable
        .observeNew { [weak self] (value: T) in
          if let value = value as? AnyObject {
            self?.setValue(value, forKey: key)
          } else {
            self?.setValue(nil, forKey: key)
          }
        }
      
      return observable
    }
  }
  
  internal func bnd_associatedObservableForOptionalValueForKey<T>(key: String, inout associationKey: String) -> Observable<T?> {
    if let observable: AnyObject = objc_getAssociatedObject(self, &associationKey) {
      return observable as! Observable<T?>
    } else {
      let observable = Observable<T?>(self.valueForKey(key) as? T ?? nil)
      objc_setAssociatedObject(self, &associationKey, observable, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      observable
        .observeNew { [weak self] (value: T?) in
          self?.setValue(value as! AnyObject?, forKey: key)
        }
      
      return observable
    }
  }
}
