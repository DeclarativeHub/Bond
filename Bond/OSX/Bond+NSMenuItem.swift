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

import Cocoa

var enabledDynamicHandleNSMenuItem: UInt8 = 0;
var stateDynamicHandleNSMenuItem: UInt8 = 0;

extension NSMenuItem: Bondable, Dynamical {

    public var designatedDynamic: Dynamic<Bool> {
        return self.dynEnabled
    }

    public var designatedBond: Bond<Bool> {
        return self.designatedDynamic.valueBond
    }

    public var dynEnabled: Dynamic<Bool> {
        if let d: AnyObject = objc_getAssociatedObject(self, &enabledDynamicHandleNSMenuItem) {
            return (d as? Dynamic<Bool>)!
        } else {
            let d = InternalDynamic<Bool>(self.enabled)
            let bond = Bond<Bool>() { [weak self] v in
                if let s = self {
                    s.enabled = v
                }
            }

            d.bindTo(bond, fire: false, strongly: false)
            d.retain(bond)
            objc_setAssociatedObject(self, &enabledDynamicHandleNSMenuItem, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return d
        }
    }

    public var dynState: Dynamic<Int> {
        if let d: AnyObject = objc_getAssociatedObject(self, &stateDynamicHandleNSMenuItem) {
            return (d as? Dynamic<Int>)!
        } else {
            let d = InternalDynamic<Int>(self.state)
            let bond = Bond<Int>() { [weak self] v in
                if let s = self {
                    s.state = v
                }
            }

            d.bindTo(bond, fire: false, strongly: false)
            d.retain(bond)
            objc_setAssociatedObject(self, &stateDynamicHandleNSMenuItem, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return d
        }
    }
    
}
