//
//  Bond+UISlider.swift
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

class SliderDynamic<T>: InternalDynamic<Float>
{
  let helper: SliderDynamicHelper
  
  init(control: UISlider) {
    self.helper = SliderDynamicHelper(control: control)
    super.init(control.value)
    self.helper.listener =  { [unowned self] in
      self.updatingFromSelf = true
      self.value = $0
      self.updatingFromSelf = false
    }
  }
}

private var designatedBondHandleUISlider: UInt8 = 0;
private var valueDynamicHandleUISlider: UInt8 = 0;

extension UISlider /*: Dynamical, Bondable */ {
  public var dynValue: Dynamic<Float> {
    if let d: AnyObject = objc_getAssociatedObject(self, &valueDynamicHandleUISlider) {
      return (d as? Dynamic<Float>)!
    } else {
      let d = SliderDynamic<Float>(control: self)
      
      let bond = Bond<Float>() { [weak self, weak d] v in
        if let s = self, d = d where !d.updatingFromSelf {
          s.value = v
        }
      }
      
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &valueDynamicHandleUISlider, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<Float> {
    return self.dynValue
  }
  
  public var designatedBond: Bond<Float> {
    return self.dynValue.valueBond
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

public func <->> (left: UISlider, right: UISlider) {
  left.designatedDynamic <->> right.designatedDynamic
}

public func <->> (left: Dynamic<Float>, right: UISlider) {
  left <->> right.designatedDynamic
}

public func <->> (left: UISlider, right: Dynamic<Float>) {
  left.designatedDynamic <->> right
}
