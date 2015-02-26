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

class TextFieldDynamic<T>: Dynamic<String>
{
  let helper: TextFieldDynamicHelper
  
  init(control: UITextField) {
    self.helper = TextFieldDynamicHelper(control: control)
    super.init(control.text)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var designatedBondHandleUITextField: UInt8 = 0;

extension UITextField /*: Dynamical, Bondable */ {
  public func textDynamic() -> Dynamic<String> {
    return TextFieldDynamic<String>(control: self)
  }
  
  public var textBond: Bond<String> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUITextField) {
      return (b as? Bond<String>)!
    } else {
      let b = Bond<String>() { [unowned self] v in self.text = v }
      objc_setAssociatedObject(self, &designatedBondHandleUITextField, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public func designatedDynamic() -> Dynamic<String> {
    return self.textDynamic()
  }
  
  public var designatedBond: Bond<String> {
    return self.textBond
  }
}

public func ->> (left: UITextField, right: Bond<String>) {
  left.designatedDynamic() ->> right
}

public func ->> <U: Bondable where U.BondType == String>(left: UITextField, right: U) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: UITextField, right: UITextField) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: UITextField, right: UILabel) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == String>(left: T, right: UITextField) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: Dynamic<String>, right: UITextField) {
  left ->> right.designatedBond
}

