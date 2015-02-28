//
//  Bond+UIBarItem.swift
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

private var enabledBondHandleUIBarItem: UInt8 = 0;
private var titleBondHandleUIBarItem: UInt8 = 0;
private var imageBondHandleUIBarItem: UInt8 = 0;

extension UIBarItem: Bondable {
  
  public var enabledBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &enabledBondHandleUIBarItem) {
      return (b as? Bond<Bool>)!
    } else {
      let b = Bond<Bool>() { [unowned self] v in self.enabled = v }
      objc_setAssociatedObject(self, &enabledBondHandleUIBarItem, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var titleBond: Bond<String> {
    if let b: AnyObject = objc_getAssociatedObject(self, &titleBondHandleUIBarItem) {
      return (b as? Bond<String>)!
    } else {
      let b = Bond<String>() { [unowned self] v in
        self.title = v
      }
      objc_setAssociatedObject(self, &titleBondHandleUIBarItem, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var imageBond: Bond<UIImage?> {
    if let b: AnyObject = objc_getAssociatedObject(self, &imageBondHandleUIBarItem) {
      return (b as? Bond<UIImage?>)!
    } else {
      let b = Bond<UIImage?>() { [unowned self] img in self.image = img }
      objc_setAssociatedObject(self, &imageBondHandleUIBarItem, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var designatedBond: Bond<Bool> {
    return self.enabledBond
  }
}
