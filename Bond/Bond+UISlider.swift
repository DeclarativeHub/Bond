//
//  Bond+UISlider.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

@objc class SliderDynamicHelper
{
  weak var control: UISlider?
  var listener: (Float -> Void)?
  
  init(control: UISlider) {
    self.control = control
    control.addTarget(self, action: Selector("valueChanged:"), forControlEvents: .ValueChanged)
  }
  
  func valueChanged(slider: UISlider) {
    self.listener?(slider.value)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .ValueChanged)
  }
}

class SliderDynamic<T>: DynamicExtended<Float>
{
  let helper: SliderDynamicHelper
  
  init(control: UISlider) {
    self.helper = SliderDynamicHelper(control: control)
    super.init(control.value)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var designatedBondHandleUISlider: UInt8 = 0;
private var valueDynamicHandleUISlider: UInt8 = 0;

extension UISlider /*: Dynamical, Bondable */ {
  public var designatedDynamic: Dynamic<Float> {
    return self.valueDynamic
  }
  
  public var designatedBond: Bond<Float> {
    return self.valueDynamic.valueBond
  }
  
  public var valueDynamic: Dynamic<Float> {
    if let d: AnyObject = objc_getAssociatedObject(self, &valueDynamicHandleUISlider) {
      return (d as? Dynamic<Float>)!
    } else {
      let d = SliderDynamic<Float>(control: self)
      let bond = d ->> { [weak self] v in if let s = self { s.value = v } }
      d.retain(bond)
      objc_setAssociatedObject(self, &valueDynamicHandleUISlider, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
}

public func ->> (left: UISlider, right: Bond<Float>) {
  left.designatedDynamic ->> right
}

public func ->> <U: Bondable where U.BondType == Float>(left: UISlider, right: U) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UISlider, right: UISlider) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<Float>, right: UISlider) {
  left ->> right.designatedBond
}

