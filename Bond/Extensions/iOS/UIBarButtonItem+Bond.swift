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

@objc class UIBarButtonItemBondHelper: NSObject
{
  weak var control: UIBarButtonItem?
  var sink: Void -> Void
  
  init(control: UIBarButtonItem, sink: Void -> Void) {
    self.control = control
    self.sink = sink
    super.init()
    control.target = self
    control.action = Selector("action:")
  }
  
  func action(control: UIBarButtonItem) {
    sink()
  }
  
  deinit {
    control?.target = nil
  }
}

extension UIBarButtonItem {
  
  private struct AssociatedKeys {
    static var TapKey = "bnd_TapKey"
    static var BarButtonItemBondHelperKey = "bnd_BarButtonItemBondHelperKey"
  }
  
  public var bnd_tap: EventProducer<Void> {
    if let bnd_tap: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.TapKey) {
      return bnd_tap as! EventProducer<Void>
    }
    else {
      var capturedSink: (Void -> Void)! = nil
      let bnd_tap = EventProducer<Void> { sink in
        capturedSink = sink
        return nil
      }
      
      let barButtonItemHelper = UIBarButtonItemBondHelper(control: self, sink: capturedSink)
      
      objc_setAssociatedObject(self, &AssociatedKeys.BarButtonItemBondHelperKey, barButtonItemHelper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      objc_setAssociatedObject(self, &AssociatedKeys.TapKey, bnd_tap, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return bnd_tap
    }
  }
}



