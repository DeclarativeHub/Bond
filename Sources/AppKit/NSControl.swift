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

import AppKit
import ReactiveKit

fileprivate extension NSControl {

  struct AssociatedKeys {
    static var ControlHelperKey = "bnd_ControlHelperKey"
  }

  @objc class BondHelper: NSObject
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
}

public extension ReactiveExtensions where Base: NSControl {

  public var controlEvent: SafeSignal<AnyObject?> {
    if let controlHelper = objc_getAssociatedObject(base, &NSControl.AssociatedKeys.ControlHelperKey) as AnyObject? {
      return (controlHelper as! NSControl.BondHelper).subject.toSignal()
    } else {
      let controlHelper = NSControl.BondHelper(control: base)
      objc_setAssociatedObject(base, &NSControl.AssociatedKeys.ControlHelperKey, controlHelper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return controlHelper.subject.toSignal()
    }
  }

  public var isEnabled: Bond<Bool> {
    return bond { $0.isEnabled = $1 }
  }

  public var objectValue: Bond<AnyObject?> {
    return bond { $0.objectValue = $1 }
  }

  public var stringValue: Bond<String> {
    return bond { $0.stringValue = $1 }
  }

  public var attributedStringleValue: Bond<NSAttributedString> {
    return bond { $0.attributedStringValue = $1 }
  }

  public var integerValue: Bond<Int> {
    return bond { $0.integerValue = $1 }
  }

  public var floatValue: Bond<Float> {
    return bond { $0.floatValue = $1 }
  }

  public var doubleValue: Bond<Double> {
    return bond { $0.doubleValue = $1 }
  }
}
