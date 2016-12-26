//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Tony Arnold (@tonyarnold)
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

import ReactiveKit
import AppKit

@objc class RKNSControlHelper: NSObject
{
  weak var control: NSControl?
  let subject = PublishSubject<AnyObject?, NoError>()

  init(control: NSControl) {
    self.control = control
    super.init()

    control.target = self
    control.action = #selector(eventHandler)
  }

  func eventHandler(_ sender: NSControl?) {
    subject.next(sender!.objectValue as AnyObject?)
  }

  deinit {
    control?.target = nil
    control?.action = nil
    subject.completed()
  }
}

extension NSControl {

  private struct AssociatedKeys {
    static var ControlHelperKey = "bnd_ControlHelperKey"
  }

  public var rControlEvent: Signal1<AnyObject?> {
    if let controlHelper = objc_getAssociatedObject(self, &AssociatedKeys.ControlHelperKey) as AnyObject? {
      return (controlHelper as! RKNSControlHelper).subject.toSignal()
    } else {
      let controlHelper = RKNSControlHelper(control: self)
      objc_setAssociatedObject(self, &AssociatedKeys.ControlHelperKey, controlHelper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return controlHelper.subject.toSignal()
    }
  }

  public var bnd_isEnabled: Bond<NSControl, Bool> {
    return Bond(target: self) { $0.isEnabled = $1 }
  }

  public var bnd_objectValue: Bond<NSControl, AnyObject?> {
    return Bond(target: self) { $0.objectValue = $1 }
  }

  public var bnd_stringValue: Bond<NSControl, String> {
    return Bond(target: self) { $0.stringValue = $1 }
  }

  public var bnd_attributedStringleValue: Bond<NSControl, NSAttributedString> {
    return Bond(target: self) { $0.attributedStringValue = $1 }
  }

  public var bnd_integerValue: Bond<NSControl, Int> {
    return Bond(target: self) { $0.integerValue = $1 }
  }

  public var bnd_floatValue: Bond<NSControl, Float> {
    return Bond(target: self) { $0.floatValue = $1 }
  }

  public var bnd_doubleValue: Bond<NSControl, Double> {
    return Bond(target: self) { $0.doubleValue = $1 }
  }
}
