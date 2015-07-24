//
//  Bond+UITextView.swift
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

private var textDynamicHandleUITextView: UInt8 = 0;
private var attributedTextDynamicHandleUITextView: UInt8 = 0;

extension UITextView: Bondable {
  
  public var dynText: Dynamic<String> {
    if let d: AnyObject = objc_getAssociatedObject(self, &textDynamicHandleUITextView) {
      return (d as? Dynamic<String>)!
    } else {
      let d: InternalDynamic<String> = dynamicObservableFor(UITextViewTextDidChangeNotification, object: self) {
        notification -> String in
        if let textView = notification.object as? UITextView  {
          return textView.text ?? ""
        } else {
          return ""
        }
      }
      
      let bond = Bond<String>() { [weak self, weak d] v in
        if let s = self, d = d where !d.updatingFromSelf {
          s.text = v
        }
      }
      
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &textDynamicHandleUITextView, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return d
    }
  }
  
  public var dynAttributedText: Dynamic<NSAttributedString> {
    if let d: AnyObject = objc_getAssociatedObject(self, &attributedTextDynamicHandleUITextView) {
      return (d as? Dynamic<NSAttributedString>)!
    } else {
      let d: InternalDynamic<NSAttributedString> = dynamicObservableFor(UITextViewTextDidChangeNotification, object: self) {
        notification -> NSAttributedString in
        if let textView = notification.object as? UITextView  {
          return textView.attributedText ?? NSAttributedString(string: "")
        } else {
          return NSAttributedString(string: "")
        }
      }
      
      let bond = Bond<NSAttributedString>() { [weak self, weak d] v in
        if let s = self, d = d where !d.updatingFromSelf {
          s.attributedText = v
        }
      }
      
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &attributedTextDynamicHandleUITextView, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return d
    }
  }
  
  public var designatedDynamic: Dynamic<String> {
    return self.dynText
  }
  
  public var designatedBond: Bond<String> {
    return self.dynText.valueBond
  }
}

public func ->> (left: UITextView, right: Bond<String>) {
  left.designatedDynamic ->> right
}

public func ->> <U: Bondable where U.BondType == String>(left: UITextView, right: U) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UITextView, right: UITextView) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UITextView, right: UILabel) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: UITextView, right: UITextField) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == String>(left: T, right: UITextView) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<String>, right: UITextView) {
  left ->> right.designatedBond
}

public func <->> (left: UITextView, right: UITextView) {
  left.designatedDynamic <->> right.designatedDynamic
}

public func <->> (left: Dynamic<String>, right: UITextView) {
  left <->> right.designatedDynamic
}

public func <->> (left: UITextView, right: Dynamic<String>) {
  left.designatedDynamic <->> right
}

public func <->> (left: UITextView, right: UITextField) {
  left.designatedDynamic <->> right.designatedDynamic
}
