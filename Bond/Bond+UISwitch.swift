//
//  Bond+UISwitch.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

@objc class SwitchDynamicHelper
{
  weak var control: UISwitch?
  var listener: (Bool -> Void)?
  
  init(control: UISwitch) {
    self.control = control
    control.addTarget(self, action: Selector("valueChanged:"), forControlEvents: .ValueChanged)
  }
  
  func valueChanged(control: UISwitch) {
    self.listener?(control.on)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .ValueChanged)
  }
}

class SwitchDynamic<T>: DynamicExtended<Bool>
{
  let helper: SwitchDynamicHelper
  
  init(control: UISwitch) {
    self.helper = SwitchDynamicHelper(control: control)
    super.init(control.on, faulty: false)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var onDynamicHandleUISwitch: UInt8 = 0;

extension UISwitch /*: Dynamical, Bondable */ {
  public var onDynamic: Dynamic<Bool> {
    if let d: AnyObject = objc_getAssociatedObject(self, &onDynamicHandleUISwitch) {
      return (d as? Dynamic<Bool>)!
    } else {
      let d = SwitchDynamic<Bool>(control: self)
      let bond = Bond<Bool>() { [weak self] v in if let s = self { s.on = v } }
      d.bindTo(bond)
      d.retain(bond)
      objc_setAssociatedObject(self, &onDynamicHandleUISwitch, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<Bool> {
    return self.onDynamic
  }
  
  public var designatedBond: Bond<Bool> {
    return self.onDynamic.valueBond
  }
}

public func ->> (left: UISwitch, right: Bond<Bool>) {
  left.designatedDynamic ->> right
}

public func ->> <U: Bondable where U.BondType == Bool>(left: UISwitch, right: U) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UISwitch, right: UIButton) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UISwitch, right: UISwitch) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == Bool>(left: T, right: UISwitch) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: Dynamic<Bool>, right: UISwitch) {
  left ->> right.designatedBond
}
