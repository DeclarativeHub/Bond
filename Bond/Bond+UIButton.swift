//
//  Bond+UIButton.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

@objc class ButtonDynamicHelper
{
  weak var control: UIButton?
  var listener: (UIControlEvents -> Void)?
  
  init(control: UIButton) {
    self.control = control
    control.addTarget(self, action: Selector("touchDown:"), forControlEvents: .TouchDown)
    control.addTarget(self, action: Selector("touchUpInside:"), forControlEvents: .TouchUpInside)
    control.addTarget(self, action: Selector("touchUpOutside:"), forControlEvents: .TouchUpOutside)
    control.addTarget(self, action: Selector("touchCancel:"), forControlEvents: .TouchCancel)
  }
  
  func touchDown(control: UIButton) {
    self.listener?(.TouchDown)
  }
  
  func touchUpInside(control: UIButton) {
    self.listener?(.TouchUpInside)
  }
  
  func touchUpOutside(control: UIButton) {
    self.listener?(.TouchUpOutside)
  }
  
  func touchCancel(control: UIButton) {
    self.listener?(.TouchCancel)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .AllEvents)
  }
}

class ButtonDynamic<T>: Dynamic<UIControlEvents>
{
  let helper: ButtonDynamicHelper
  
  init(control: UIButton) {
    self.helper = ButtonDynamicHelper(control: control)
    super.init(UIControlEvents.allZeros)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var eventDynamicHandleUIButton: UInt8 = 0;
private var enabledBondHandleUIButton: UInt8 = 0;
private var titleBondHandleUIButton: UInt8 = 0;
private var imageForNormalStateBondHandleUIButton: UInt8 = 0;

extension UIButton /*: Dynamical, Bondable */ {

  public var eventDynamic: Dynamic<UIControlEvents> {
    if let d: AnyObject = objc_getAssociatedObject(self, &eventDynamicHandleUIButton) {
      return (d as? Dynamic<UIControlEvents>)!
    } else {
      let d = ButtonDynamic<UIControlEvents>(control: self)
      objc_setAssociatedObject(self, &eventDynamicHandleUIButton, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var enabledBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &enabledBondHandleUIButton) {
      return (b as? Bond<Bool>)!
    } else {
      let b = Bond<Bool>() { [unowned self] v in self.enabled = v }
      objc_setAssociatedObject(self, &enabledBondHandleUIButton, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var titleBond: Bond<String> {
    if let b: AnyObject = objc_getAssociatedObject(self, &titleBondHandleUIButton) {
      return (b as? Bond<String>)!
    } else {
      let b = Bond<String>() { [unowned self] v in
        if let label = self.titleLabel {
          label.text = v
        }
      }
      objc_setAssociatedObject(self, &titleBondHandleUIButton, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var imageForNormalStateBond: Bond<UIImage?> {
    if let b: AnyObject = objc_getAssociatedObject(self, &imageForNormalStateBondHandleUIButton) {
      return (b as? Bond<UIImage?>)!
    } else {
      let b = Bond<UIImage?>() { [unowned self] img in self.setImage(img, forState: .Normal) }
      objc_setAssociatedObject(self, &imageForNormalStateBondHandleUIButton, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var designatedDynamic: Dynamic<UIControlEvents> {
    return self.eventDynamic
  }
  
  public var designatedBond: Bond<Bool> {
    return self.enabledBond
  }
}

public func ->> (left: UIButton, right: Bond<UIControlEvents>) {
  left.designatedDynamic ->> right
}

public func ->> <U: Bondable where U.BondType == UIControlEvents>(left: UIButton, right: U) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == Bool>(left: T, right: UIButton) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: Dynamic<Bool>, right: UIButton) {
  left ->> right.designatedBond
}


