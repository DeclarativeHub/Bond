//
//  Bond+UITextField.swift
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

class TextFieldDynamic<T>: InternalDynamic<String>
{
  let helper: TextFieldDynamicHelper
  
  init(control: UITextField) {
    self.helper = TextFieldDynamicHelper(control: control)
    super.init(control.text ?? "")
    self.helper.listener =  { [unowned self] in
      self.updatingFromSelf = true
      self.value = $0
      self.updatingFromSelf = false
    }
  }
}

private var textDynamicHandleUITextField: UInt8 = 0;
private var enabledDynamicHandleUITextField: UInt8 = 0;

extension UITextField /*: Dynamical, Bondable */ {
  
  public var dynText: Dynamic<String> {
    if let d: AnyObject = objc_getAssociatedObject(self, &textDynamicHandleUITextField) {
      return (d as? Dynamic<String>)!
    } else {
      let d = TextFieldDynamic<String>(control: self)
      let bond = Bond<String>() { [weak self, weak d] v in
        if let s = self, d = d where !d.updatingFromSelf {
          s.text = v
        }
      }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &textDynamicHandleUITextField, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }

  public var dynEnabled: Dynamic<Bool> {
    if let d: AnyObject = objc_getAssociatedObject(self, &enabledDynamicHandleUITextField) {
      return (d as? Dynamic<Bool>)!
    } else {
      let d = InternalDynamic<Bool>(self.enabled)
      let bond = Bond<Bool>() { [weak self] v in if let s = self { s.enabled = v } }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &enabledDynamicHandleUITextField, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }

  public var designatedDynamic: Dynamic<String> {
    return self.dynText
  }
  
  public var designatedBond: Bond<String> {
    return self.dynText.valueBond
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

public func ->> (left: UITextField, right: UITextView) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == String>(left: T, right: UITextField) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<String>, right: UITextField) {
  left ->> right.designatedBond
}

public func <->> (left: UITextField, right: UITextField) {
  left.designatedDynamic <->> right.designatedDynamic
}

public func <->> (left: Dynamic<String>, right: UITextField) {
  left <->> right.designatedDynamic
}

public func <->> (left: UITextField, right: Dynamic<String>) {
  left.designatedDynamic <->> right
}

public func <->> (left: UITextField, right: UITextView) {
  left.designatedDynamic <->> right.designatedDynamic
}
