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

var stringDynamicHandleNSTextView: UInt8 = 0;

extension NSTextView: Dynamical, Bondable {

    public var designatedDynamic: Dynamic<String> {
        return self.dynString
    }

    public var designatedBond: Bond<String> {
        return self.designatedDynamic.valueBond
    }

    public var dynString: Dynamic<String> {
        if let d: AnyObject = objc_getAssociatedObject(self, &stringDynamicHandleNSTextView) {
            return (d as? Dynamic<String>)!
        } else {
            let d: InternalDynamic<String> = dynamicObservableFor(NSTextViewDidChangeTypingAttributesNotification, object: self) {
                notification -> String in
                if let textView = notification.object as? NSTextView  {
                    return textView.string ?? ""
                } else {
                    return ""
                }
            }

            let bond = Bond<String>() { [weak d] v in // NSTextView cannot be referenced weakly
                if let d = d where !d.updatingFromSelf {
                    self.string = v
                }
            }
          
            d.bindTo(bond, fire: false, strongly: false)
            d.retain(bond)
            objc_setAssociatedObject(self, &stringDynamicHandleNSTextView, d, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return d
        }
    }

}

public func ->> (left: NSTextView, right: Bond<String>) {
    left.designatedDynamic ->> right
}

public func ->> <U: Bondable where U.BondType == String>(left: NSTextView, right: U) {
    left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: NSTextView, right: NSTextView) {
    left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: NSTextView, right: NSTextField) {
    left.designatedDynamic ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == String>(left: T, right: NSTextView) {
    left.designatedDynamic ->> right.designatedBond
}

public func ->> (left: Dynamic<String>, right: NSTextView) {
    left ->> right.designatedBond
}

public func <->> (left: NSTextView, right: NSTextView) {
    left.designatedDynamic <->> right.designatedDynamic
}

public func <->> (left: Dynamic<String>, right: NSTextView) {
    left <->> right.designatedDynamic
}

public func <->> (left: NSTextView, right: Dynamic<String>) {
    left.designatedDynamic <->> right
}

public func <->> (left: NSTextView, right: NSTextField) {
    left.designatedDynamic <->> right.designatedDynamic
}
