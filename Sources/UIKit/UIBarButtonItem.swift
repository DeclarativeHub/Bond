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

import UIKit
import ReactiveKit

extension UIBarButtonItem {

  private struct AssociatedKeys {
    static var BarButtonItemHelperKey = "bnd_BarButtonItemHelperKey"
  }

  public var bnd_tap: Signal1<Void> {
    if let target = objc_getAssociatedObject(self, &AssociatedKeys.BarButtonItemHelperKey) as AnyObject? {
      return (target as! BNDBarButtonItemTarget).subject.toSignal()
    } else {
      let target = BNDBarButtonItemTarget(barButtonItem: self)
      objc_setAssociatedObject(self, &AssociatedKeys.BarButtonItemHelperKey, target, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return target.subject.toSignal()
    }
  }
}

@objc fileprivate class BNDBarButtonItemTarget: NSObject
{
  weak var barButtonItem: UIBarButtonItem?
  let subject = PublishSubject<Void, NoError>()

  init(barButtonItem: UIBarButtonItem) {
    self.barButtonItem = barButtonItem
    super.init()

    barButtonItem.target = self
    barButtonItem.action = #selector(eventHandler)
  }

  func eventHandler() {
    subject.next()
  }

  deinit {
    barButtonItem?.target = nil
    barButtonItem?.action = nil
    subject.completed()
  }
}
