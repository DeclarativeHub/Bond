//
//  Bond+UIProgressView.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

private var designatedBondHandleUIProgressView: UInt8 = 0;

extension UIProgressView: Bondable {
  public var progressBond: Bond<Float> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUIProgressView) {
      return (b as? Bond<Float>)!
    } else {
      let b = Bond<Float>() { [unowned self] v in self.progress = v }
      objc_setAssociatedObject(self, &designatedBondHandleUIProgressView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var designatedBond: Bond<Float> {
    return self.progressBond
  }
}
