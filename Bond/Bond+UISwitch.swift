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

class SwitchDynamic<T>: Dynamic<Bool>
{
  let helper: SwitchDynamicHelper
  
  init(control: UISwitch) {
    self.helper = SwitchDynamicHelper(control: control)
    super.init(control.on)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var designatedBondHandleUISwitch: UInt8 = 0;

extension UISwitch /*: Dynamical, Bondable */ {
  public func onDynamic() -> Dynamic<Bool> {
    return SwitchDynamic<Bool>(control: self)
  }
  
  public var onBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUISwitch) {
      return (b as? Bond<Bool>)!
    } else {
      let b = Bond<Bool>() { [unowned self] v in self.on = v }
      objc_setAssociatedObject(self, &designatedBondHandleUISwitch, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public func designatedDynamic() -> Dynamic<Bool> {
    return self.onDynamic()
  }
  
  public var designatedBond: Bond<Bool> {
    return self.onBond
  }
}

public func ->> (left: UISwitch, right: Bond<Bool>) {
  left.designatedDynamic() ->> right
}

public func ->> <U: Bondable where U.BondType == Bool>(left: UISwitch, right: U) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: UISwitch, right: UIButton) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: UISwitch, right: UISwitch) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == Bool>(left: T, right: UISwitch) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: Dynamic<Bool>, right: UISwitch) {
  left ->> right.designatedBond
}
