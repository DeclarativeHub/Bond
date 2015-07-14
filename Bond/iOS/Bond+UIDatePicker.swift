//
//  Bond+UIDatePicker.swift
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

import UIKit

@objc class DatePickerDynamicHelper
{
  weak var control: UIDatePicker?
  var listener: (NSDate -> Void)?
  
  init(control: UIDatePicker) {
    self.control = control
    control.addTarget(self, action: Selector("valueChanged:"), forControlEvents: .ValueChanged)
  }
  
  func valueChanged(control: UIDatePicker) {
    self.listener?(control.date)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .ValueChanged)
  }
}

class DatePickerDynamic<T>: InternalDynamic<NSDate>
{
  let helper: DatePickerDynamicHelper
  
  init(control: UIDatePicker) {
    self.helper = DatePickerDynamicHelper(control: control)
    super.init(control.date)
    self.helper.listener =  { [unowned self] in
      self.updatingFromSelf = true
      self.value = $0
      self.updatingFromSelf = false
    }
  }
}

private var dateDynamicHandleUIDatePicker: UInt8 = 0;

extension UIDatePicker /*: Dynamical, Bondable */ {
  public var dynDate: Dynamic<NSDate> {
    if let d: AnyObject = objc_getAssociatedObject(self, &dateDynamicHandleUIDatePicker) {
      return (d as? Dynamic<NSDate>)!
    } else {
      let d = DatePickerDynamic<NSDate>(control: self)
      
      let bond = Bond<NSDate>() { [weak self, weak d] v in
        if let s = self, d = d where !d.updatingFromSelf {
          s.date = v
        }
      }
      
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &dateDynamicHandleUIDatePicker, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<NSDate> {
    return self.dynDate
  }
  
  public var designatedBond: Bond<NSDate> {
    return self.dynDate.valueBond
  }
}

public func ->> (left: UIDatePicker, right: Bond<NSDate>) {
  left.designatedDynamic ->> right
}

public func ->> <U: Bondable where U.BondType == NSDate>(left: UIDatePicker, right: U) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UIDatePicker, right: UIDatePicker) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<NSDate>, right: UIDatePicker) {
  left ->> right.designatedBond
}

public func <->> (left: UIDatePicker, right: UIDatePicker) {
  left.designatedDynamic <->> right.designatedDynamic
}

public func <->> (left: Dynamic<NSDate>, right: UIDatePicker) {
  left <->> right.designatedDynamic
}

public func <->> (left: UIDatePicker, right: Dynamic<NSDate>) {
  left.designatedDynamic <->> right
}
