//
//  Bond+UIDatePicker.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
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

class DatePickerDynamic<T>: DynamicExtended<NSDate>
{
  let helper: DatePickerDynamicHelper
  
  init(control: UIDatePicker) {
    self.helper = DatePickerDynamicHelper(control: control)
    super.init(control.date)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var dateDynamicHandleUIDatePicker: UInt8 = 0;

extension UIDatePicker /*: Dynamical, Bondable */ {
  public var dateDynamic: Dynamic<NSDate> {
    if let d: AnyObject = objc_getAssociatedObject(self, &dateDynamicHandleUIDatePicker) {
      return (d as? Dynamic<NSDate>)!
    } else {
      let d = DatePickerDynamic<NSDate>(control: self)
      let bond = d ->> { [weak self] v in if let s = self { s.date = v } }
      d.retain(bond)
      objc_setAssociatedObject(self, &dateDynamicHandleUIDatePicker, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<NSDate> {
    return self.dateDynamic
  }
  
  public var designatedBond: Bond<NSDate> {
    return self.dateDynamic.valueBond
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
