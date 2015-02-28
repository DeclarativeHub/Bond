//
//  Bond+UITextView.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

private var textDynamicHandleUITextView: UInt8 = 0;

extension UITextView: Bondable {
  
  public var textDynamic: Dynamic<String> {
    if let d: AnyObject = objc_getAssociatedObject(self, &textDynamicHandleUITextView) {
      return (d as? Dynamic<String>)!
    } else {
      let d = Dynamic.asObservableFor(UITextViewTextDidChangeNotification, object: self) {
        notification -> String in
        if let textView = notification.object as? UITextView  {
          return textView.text ?? ""
        } else {
          return ""
        }
      }
      
      let bond = Bond<String>() { [weak self] v in if let s = self { s.text = v } }
      d.bindTo(bond)
      d.retain(bond)
      objc_setAssociatedObject(self, &textDynamicHandleUITextView, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<String> {
    return self.textDynamic
  }
  
  public var designatedBond: Bond<String> {
    return self.textDynamic.valueBond
  }
}
