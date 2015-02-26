//
//  Bond+UIImageView.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

var associatedObjectHandleUIImageView: UInt8 = 0;

extension UIImageView: Bondable {
  public var imageBond: Bond<UIImage?> {
    if let b: AnyObject = objc_getAssociatedObject(self, &associatedObjectHandleUIImageView) {
      return (b as? Bond<UIImage?>)!
    } else {
      let b = Bond<UIImage?>() { [unowned self] v in self.image = v }
      objc_setAssociatedObject(self, &associatedObjectHandleUIImageView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var designatedBond: Bond<UIImage?> {
    return self.imageBond
  }
}
