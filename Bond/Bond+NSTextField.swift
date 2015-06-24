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

class TextFieldDynamicHelper: NSObject {

    weak var control: NSTextField?
    var listener: (String -> Void)?

    init(control: NSTextField) {
        self.control = control
        super.init()
        control.target = self
        control.action = Selector("textChanged:")
    }

    @objc func textChanged(sender: AnyObject?) {
        self.listener?(control?.stringValue ?? "")
    }

}

class TextFieldDynamic<T>: InternalDynamic<String> {

    let helper: TextFieldDynamicHelper

    init(control: NSTextField) {
        self.helper = TextFieldDynamicHelper(control: control)
        super.init(control.stringValue ?? "")
        self.helper.listener =  { [unowned self] in
          self.updatingFromSelf = true
          self.value = $0
          self.updatingFromSelf = false
      }
    }

}

var stringValueDynamicHandleNSTextField: UInt8 = 0;

extension NSTextField: Dynamical, Bondable {

    public var designatedDynamic: Dynamic<String> {
        return self.dynText
    }

    public var designatedBond: Bond<String> {
        return self.designatedDynamic.valueBond
    }

    public var dynText: Dynamic<String> {
        if let d: AnyObject = objc_getAssociatedObject(self, &stringValueDynamicHandleNSTextField) {
            return (d as? Dynamic<String>)!
        } else {
            let d = TextFieldDynamic<String>(control: self)
          
            let bond = Bond<String>() { [weak self, weak d] v in
                if let s = self, d = d where !d.updatingFromSelf {
                    s.stringValue = v
                }
            }
          
            d.bindTo(bond, fire: false, strongly: false)
            d.retain(bond)
            objc_setAssociatedObject(self, &stringValueDynamicHandleNSTextField, d, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return d
        }
    }

}

public func ->> (left: NSTextField, right: Bond<String>) {
    left.designatedDynamic ->> right
}

public func ->> <U: Bondable where U.BondType == String>(left: NSTextField, right: U) {
    left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: NSTextField, right: NSTextField) {
    left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: NSTextField, right: NSTextView) {
    left.designatedDynamic ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == String>(left: T, right: NSTextField) {
    left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<String>, right: NSTextField) {
    left ->> right.designatedBond
}

public func <->> (left: NSTextField, right: NSTextField) {
    left.designatedDynamic <->> right.designatedDynamic
}

public func <->> (left: Dynamic<String>, right: NSTextField) {
    left <->> right.designatedDynamic
}

public func <->> (left: NSTextField, right: Dynamic<String>) {
    left.designatedDynamic <->> right
}

public func <->> (left: NSTextField, right: NSTextView) {
    left.designatedDynamic <->> right.designatedDynamic
}
