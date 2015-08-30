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

import UIKit

extension UIDatePicker {
  
  private struct AssociatedKeys {
    static var DateKey = "bnd_DateKey"
  }
  
  public var bnd_date: Observable<NSDate> {
    if let bnd_date: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.DateKey) {
      return bnd_date as! Observable<NSDate>
    } else {
      let bnd_date = Observable<NSDate>(self.date)
      objc_setAssociatedObject(self, &AssociatedKeys.DateKey, bnd_date, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      var updatingFromSelf: Bool = false
      
      bnd_date.observeNew { [weak self] (date: NSDate) in
        if !updatingFromSelf {
          self?.date = date
        }
      }
      
      self.bnd_controlEvent.filter { $0 == UIControlEvents.ValueChanged }.observe { [weak self, weak bnd_date] event in
        guard let unwrappedSelf = self, let bnd_date = bnd_date else { return }
        updatingFromSelf = true
        bnd_date.next(unwrappedSelf.date)
        updatingFromSelf = false
      }
      
      return bnd_date
    }
  }
}
