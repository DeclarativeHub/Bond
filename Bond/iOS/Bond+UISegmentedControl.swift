//
//  Bond+UISegmentedControl.swift
//  Bond
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Austin Cooley (@adcooley)
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

@objc class SegmentedControlDynamicHelper
{
  weak var control: UISegmentedControl?
  var listener: (UIControlEvents -> Void)?
  
  init(control: UISegmentedControl) {
    self.control = control
    control.addTarget(self, action: Selector("valueChanged:"), forControlEvents: UIControlEvents.ValueChanged)
  }
  
  func valueChanged(control: UISegmentedControl) {
    self.listener?(.ValueChanged)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .AllEvents)
  }
}

class SegmentedControlDynamic<T>: InternalDynamic<UIControlEvents>
{
  let helper: SegmentedControlDynamicHelper
  
  init(control: UISegmentedControl) {
    self.helper = SegmentedControlDynamicHelper(control: control)
    super.init()
    self.helper.listener =  { [unowned self] in
      self.value = $0
    }
  }
}

private var eventDynamicHandleUISegmentedControl: UInt8 = 0;

extension UISegmentedControl /*: Dynamical, Bondable */ {
  
  public var dynEvent: Dynamic<UIControlEvents> {
    if let d: AnyObject = objc_getAssociatedObject(self, &eventDynamicHandleUISegmentedControl) {
      return (d as? Dynamic<UIControlEvents>)!
    } else {
      let d = SegmentedControlDynamic<UIControlEvents>(control: self)
      objc_setAssociatedObject(self, &eventDynamicHandleUISegmentedControl, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<UIControlEvents> {
    return self.dynEvent
  }
  
  public var designatedBond: Bond<UIControlEvents> {
    return self.dynEvent.valueBond
  }
}

public func ->> (left: UISegmentedControl, right: Bond<UIControlEvents>) {
  left.designatedDynamic ->> right
}

public func ->> <U: Bondable where U.BondType == UIControlEvents>(left: UISegmentedControl, right: U) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == UIControlEvents>(left: T, right: UISegmentedControl) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<UIControlEvents>, right: UISegmentedControl) {
  left ->> right.designatedBond
}


