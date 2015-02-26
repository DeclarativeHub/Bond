//
//  Bond+UIBarItem.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
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
