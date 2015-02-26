//
//  Bond+UITextField.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

@objc class TextFieldDynamicHelper
{
  weak var control: UITextField?
  var listener: (String -> Void)?
  
  init(control: UITextField) {
    self.control = control
    control.addTarget(self, action: Selector("editingChanged:"), forControlEvents: .EditingChanged)
  }
  
  func editingChanged(control: UITextField) {
    self.listener?(control.text ?? "")
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .EditingChanged)
  }
}

class TextFieldDynamic<T>: DynamicExtended<String>
{
  let helper: TextFieldDynamicHelper
  
  init(control: UITextField) {
    self.helper = TextFieldDynamicHelper(control: control)
    super.init(control.text)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var textDynamicHandleUITextField: UInt8 = 0;

extension UITextField /*: Dynamical, Bondable */ {
  
  public var textDynamic: Dynamic<String> {
    if let d: AnyObject = objc_getAssociatedObject(self, &textDynamicHandleUITextField) {
      return (d as? Dynamic<String>)!
    } else {
      let d = TextFieldDynamic<String>(control: self)
      let bond = d ->> { [weak self] v in if let s = self { s.text = v } }
      d.retain(bond)
      objc_setAssociatedObject(self, &textDynamicHandleUITextField, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<String> {
    return self.textDynamic
  }
  
  public var designatedBond: Bond<String> {
    return self.textDynamic.valueBond
  }
}

public func ->> (left: UITextField, right: Bond<String>) {
  left.designatedDynamic ->> right
}

public func ->> <U: Bondable where U.BondType == String>(left: UITextField, right: U) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UITextField, right: UITextField) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UITextField, right: UILabel) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == String>(left: T, right: UITextField) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: Dynamic<String>, right: UITextField) {
  left ->> right.designatedBond
}

public func <->> (left: Dynamic<String>, right: UITextField) {
  left <->> right.textDynamic
}

