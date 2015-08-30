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

extension UISwitch {
  
  private struct AssociatedKeys {
    static var OnKey = "bnd_OnKey"
  }
  
  public var bnd_on: Observable<Bool> {
    if let bnd_on: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.OnKey) {
      return bnd_on as! Observable<Bool>
    } else {
      let bnd_on = Observable<Bool>(self.on)
      objc_setAssociatedObject(self, &AssociatedKeys.OnKey, bnd_on, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      var updatingFromSelf: Bool = false
      
      bnd_on.observeNew { [weak self] on in
        if !updatingFromSelf {
          self?.on = on
        }
      }
      
      self.bnd_controlEvent.filter { $0 == UIControlEvents.ValueChanged }.observe { [weak self, weak bnd_on] event in
        guard let unwrappedSelf = self, let bnd_on = bnd_on else { return }
        updatingFromSelf = true
        bnd_on.next(unwrappedSelf.on)
        updatingFromSelf = false
      }
      
      return bnd_on
    }
  }
}
