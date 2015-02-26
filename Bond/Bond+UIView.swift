//
//  Bond+UIView.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

private var backgroundColorBondHandleUIView: UInt8 = 0;
private var alphaBondHandleUIView: UInt8 = 0;
private var hiddenBondHandleUIView: UInt8 = 0;

extension UIView {
  public var backgroundColorBond: Bond<UIColor> {
    if let b: AnyObject = objc_getAssociatedObject(self, &backgroundColorBondHandleUIView) {
      return (b as? Bond<UIColor>)!
    } else {
      let b = Bond<UIColor>() { [unowned self] v in self.backgroundColor = v }
      objc_setAssociatedObject(self, &backgroundColorBondHandleUIView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var alphaBond: Bond<CGFloat> {
    if let b: AnyObject = objc_getAssociatedObject(self, &alphaBondHandleUIView) {
      return (b as? Bond<CGFloat>)!
    } else {
      let b = Bond<CGFloat>() { [unowned self] v in self.alpha = v }
      objc_setAssociatedObject(self, &alphaBondHandleUIView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var hiddenBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &hiddenBondHandleUIView) {
      return (b as? Bond<Bool>)!
    } else {
      let b = Bond<Bool>() { [unowned self] v in self.hidden = v }
      objc_setAssociatedObject(self, &hiddenBondHandleUIView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
}
