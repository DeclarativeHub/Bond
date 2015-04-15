//
//  Bond+UIView.swift
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

private var backgroundColorDynamicHandleUIView: UInt8 = 0;
private var alphaDynamicHandleUIView: UInt8 = 0;
private var hiddenDynamicHandleUIView: UInt8 = 0;

extension UIView {
  
  public var dynBackgroundColor: Dynamic<UIColor> {
    if let d: AnyObject = objc_getAssociatedObject(self, &backgroundColorDynamicHandleUIView) {
      return (d as? Dynamic<UIColor>)!
    } else {
      let d = InternalDynamic<UIColor>(self.backgroundColor ?? UIColor.clearColor())
      let bond = Bond<UIColor>() { [weak self] v in if let s = self { s.backgroundColor = v } }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &backgroundColorDynamicHandleUIView, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var dynAlpha: Dynamic<CGFloat> {
    if let d: AnyObject = objc_getAssociatedObject(self, &alphaDynamicHandleUIView) {
      return (d as? Dynamic<CGFloat>)!
    } else {
      let d = InternalDynamic<CGFloat>(self.alpha)
      let bond = Bond<CGFloat>() { [weak self] v in if let s = self { s.alpha = v } }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &alphaDynamicHandleUIView, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
  
  public var dynHidden: Dynamic<Bool> {
    if let d: AnyObject = objc_getAssociatedObject(self, &hiddenDynamicHandleUIView) {
      return (d as? Dynamic<Bool>)!
    } else {
      let d = InternalDynamic<Bool>(self.hidden)
      let bond = Bond<Bool>() { [weak self] v in if let s = self { s.hidden = v } }
      d.bindTo(bond, fire: false, strongly: false)
      d.retain(bond)
      objc_setAssociatedObject(self, &hiddenDynamicHandleUIView, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return d
    }
  }
}
