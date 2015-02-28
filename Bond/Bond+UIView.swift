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
