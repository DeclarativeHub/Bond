//
//  Bond+UISwitch.swift
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

class SwitchDynamic<T>: InternalDynamic<Bool>
{
  let helper: SwitchDynamicHelper
  
  init(control: UISwitch) {
    self.helper = SwitchDynamicHelper(control: control)
    super.init(control.on)
    self.helper.listener =  { [unowned self] in
      self.updatingFromSelf = true
      self.value = $0
      self.updatingFromSelf = false
    }
  }
}

private var onDynamicHandleUISwitch: UInt8 = 0;

extension UISwitch /*: Dynamical, Bondable */ {
  public var dynOn: Dynamic<Bool> {
    if let d: AnyObject = objc_getAssociatedObject(self, &onDynamicHandleUISwitch) {
      return (d as? Dynamic<Bool>)!
    } else {
      let d = SwitchDynamic<Bool>(control: self)
      
      let bond = Bond<Bool>() { [weak self, weak d] v in
        if let s = self, d = d where !d.updatingFromSelf {
          s.on = v
        }
      }
      
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &onDynamicHandleUISwitch, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<Bool> {
    return self.dynOn
  }
  
  public var designatedBond: Bond<Bool> {
    return self.dynOn.valueBond
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
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<Bool>, right: UISwitch) {
  left ->> right.designatedBond
}

public func <->> (left: UISwitch, right: UISwitch) {
  left.designatedDynamic <->> right.designatedDynamic
}

public func <->> (left: Dynamic<Bool>, right: UISwitch) {
  left <->> right.designatedDynamic
}

public func <->> (left: UISwitch, right: Dynamic<Bool>) {
  left.designatedDynamic <->> right
}

