//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Tony Arnold (@tonyarnold)
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

import QuartzCore

var dynamicHandleCALayer_backgroundColor: UInt8 = 0;
var dynamicHandleCALayer_contents: UInt8 = 0;
var dynamicHandleCALayer_opacity: UInt8 = 0;

extension CALayer: Bondable, Dynamical {

    public var designatedDynamic: Dynamic<AnyObject!> {
        return self.bindableContents
    }

    public var designatedBond: Bond<AnyObject!> {
        return self.designatedDynamic.valueBond
    }

    public var bindableBackgroundColor: Dynamic<CGColor?> {
        if let d: AnyObject = objc_getAssociatedObject(self, &dynamicHandleCALayer_backgroundColor) {
            return (d as? Dynamic<CGColor?>)!
        } else {
            let d = InternalDynamic<CGColor?>(self.backgroundColor)
            let bond = Bond<CGColor?>() { [weak self] v in
                if let s = self {
                    s.backgroundColor = v
                }
            }

            d.bindTo(bond, fire: false, strongly: false)
            d.retain(bond)
            objc_setAssociatedObject(self, &dynamicHandleCALayer_backgroundColor, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return d
        }
    }

    public var bindableContents: Dynamic<AnyObject!> {
        if let d: AnyObject = objc_getAssociatedObject(self, &dynamicHandleCALayer_contents) {
            return (d as? Dynamic<AnyObject!>)!
        } else {
            let d = InternalDynamic<AnyObject!>(self.contents)
            let bond = Bond<AnyObject!>() { [weak self] v in
                if let s = self {
                    s.contents = v
                }
            }

            d.bindTo(bond, fire: false, strongly: false)
            d.retain(bond)
            objc_setAssociatedObject(self, &dynamicHandleCALayer_contents, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return d
        }
    }

    public var bindableOpacity: Dynamic<Float> {
        if let d: AnyObject = objc_getAssociatedObject(self, &dynamicHandleCALayer_opacity) {
            return (d as? Dynamic<Float>)!
        } else {
            let d = InternalDynamic<Float>(self.opacity)
            let bond = Bond<Float>() { [weak self] v in
                if let s = self {
                    s.opacity = v
                }
            }

            d.bindTo(bond, fire: false, strongly: false)
            d.retain(bond)
            objc_setAssociatedObject(self, &dynamicHandleCALayer_opacity, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return d
        }
    }
    
}
