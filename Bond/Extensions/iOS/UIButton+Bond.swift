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

extension UIButton {
  
  private struct AssociatedKeys {
    static var TitleKey = "bnd_TitleKey"
  }
  
  public var bnd_title: Observable<String> {
    if let bnd_title: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.TitleKey) {
      return bnd_title as! Observable<String>
    } else {
      let bnd_title = Observable<String>(self.titleLabel?.text ?? "")
      objc_setAssociatedObject(self, &AssociatedKeys.TitleKey, bnd_title, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      bnd_title.observeNew { [weak self] (text: String) in
        self?.setTitle(text, forState: UIControlState.Normal)
      }
      
      return bnd_title
    }
  }
  
  public var bnd_tap: Observable<Void> {
    return self.bnd_controlEvent.filter { $0 == UIControlEvents.TouchUpInside }.map { e in }
  }
}
