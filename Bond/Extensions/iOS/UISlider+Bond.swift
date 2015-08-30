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

extension UISlider {
  
  private struct AssociatedKeys {
    static var ValueKey = "bnd_ValueKey"
  }
  
  public var bnd_value: Observable<Float> {
    if let bnd_value: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.ValueKey) {
      return bnd_value as! Observable<Float>
    } else {
      let bnd_value = Observable<Float>(self.value)
      objc_setAssociatedObject(self, &AssociatedKeys.ValueKey, bnd_value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      var updatingFromSelf: Bool = false
      
      bnd_value.observeNew { [weak self] value in
        if !updatingFromSelf {
          self?.value = value
        }
      }
      
      self.bnd_controlEvent.filter { $0 == UIControlEvents.ValueChanged }.observe { [weak self, weak bnd_value] event in
        guard let unwrappedSelf = self, let bnd_value = bnd_value else { return }
        updatingFromSelf = true
        bnd_value.next(unwrappedSelf.value)
        updatingFromSelf = false
      }
      
      return bnd_value
    }
  }
}
