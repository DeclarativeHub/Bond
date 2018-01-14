//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

import ReactiveKit

public struct Bond<Element>: BindableProtocol {

    private weak var target: Deallocatable?
    private let setter: (AnyObject, Element) -> Void
    private let context: ExecutionContext

    public init<Target: Deallocatable>(target: Target, context: ExecutionContext, setter: @escaping (Target, Element) -> Void) {
        self.target = target
        self.context = context
        self.setter =  { setter($0 as! Target, $1) }
    }

    public init<Target: Deallocatable>(target: Target, setter: @escaping (Target, Element) -> Void) where Target: BindingExecutionContextProvider {
        self.target = target
        self.context = target.bindingExecutionContext
        self.setter =  { setter($0 as! Target, $1) }
    }

    public func bind(signal: Signal<Element, NoError>) -> Disposable {
        if let target = target {
            return signal.take(until: target.deallocated).observeNext { element in
                self.context.execute {
                    if let target = self.target {
                        self.setter(target, element)
                    }
                }
            }
        } else {
            return NonDisposable.instance
        }
    }
}

extension ReactiveExtensions where Base: Deallocatable {

    /// Creates a bond on the receiver.
    public func bond<Element>(context: ExecutionContext, setter: @escaping (Base, Element) -> Void) -> Bond<Element> {
        return Bond(target: base, context: context, setter: setter)
    }
}

extension ReactiveExtensions where Base: Deallocatable, Base: BindingExecutionContextProvider {

    /// Creates a bond on the receiver.
    public func bond<Element>(setter: @escaping (Base, Element) -> Void) -> Bond<Element> {
        return Bond(target: base, setter: setter)
    }
}
