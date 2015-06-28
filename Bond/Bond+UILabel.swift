//
//  Bond+UILabel.swift
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

private var textDynamicHandleUILabel: UInt8 = 0;
private var attributedTextDynamicHandleUILabel: UInt8 = 0;
private var textColorDynamicHandleUILabel: UInt8 = 0;

extension UILabel: Bondable {
  public var dynText: Dynamic<String> {
    if let d: AnyObject = objc_getAssociatedObject(self, &textDynamicHandleUILabel) {
      return (d as? Dynamic<String>)!
    } else {
      let d = InternalDynamic<String>(self.text ?? "")
      let bond = Bond<String>() { [weak self] v in if let s = self { s.text = v } }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &textDynamicHandleUILabel, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
    
  public var dynAttributedText: Dynamic<NSAttributedString> {
    if let d: AnyObject = objc_getAssociatedObject(self, &attributedTextDynamicHandleUILabel) {
      return (d as? Dynamic<NSAttributedString>)!
    } else {
      let d = InternalDynamic<NSAttributedString>(self.attributedText ?? NSAttributedString(string: ""))
      let bond = Bond<NSAttributedString>() { [weak self] v in if let s = self { s.attributedText = v } }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &attributedTextDynamicHandleUILabel, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
    
  public var dynTextColor: Dynamic<UIColor> {
    if let d: AnyObject = objc_getAssociatedObject(self, &textColorDynamicHandleUILabel) {
      return (d as? Dynamic<UIColor>)!
    } else {
      let d = InternalDynamic<UIColor>(self.textColor ?? UIColor.blackColor())
      let bond = Bond<UIColor>() { [weak self] v in if let s = self { s.textColor = v } }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &textColorDynamicHandleUILabel, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
    
  public var designatedBond: Bond<String> {
    return self.dynText.valueBond
  }
}
