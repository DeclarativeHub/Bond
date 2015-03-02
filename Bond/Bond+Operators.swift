//
//  Bond+Operators.swift
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

// MARK: Operators

infix operator ->> { associativity left precedence 105 }
infix operator ->| { associativity left precedence 105 }
infix operator <->> { associativity left precedence 100 }


// MARK: Bind and fire

public func ->> <T>(left: Dynamic<T>, right: Bond<T>) {
  left.bindTo(right)
}

public func ->> <T>(left: Dynamic<T>, right: Dynamic<T>) {
  left ->> right.valueBond
}

public func ->> <T: Dynamical, U where T.DynamicType == U>(left: T, right: Bond<U>) {
  left.designatedDynamic ->> right
}

public func ->> <T: Dynamical, U: Bondable where T.DynamicType == U.BondType>(left: T, right: U) {
  left.designatedDynamic ->> right.designatedBond
}

public func ->> <T, U: Bondable where U.BondType == T>(left: Dynamic<T>, right: U) {
  left ->> right.designatedBond
}


// MARK: Bind only

public func ->| <T>(left: Dynamic<T>, right: Bond<T>) {
  right.bind(left, fire: false)
}

public func ->| <T>(left: Dynamic<T>, right: T -> Void) -> Bond<T> {
  let bond = Bond<T>(right)
  bond.bind(left, fire: false)
  return bond
}

public func ->| <T: Dynamical, U where T.DynamicType == U>(left: T, right: Bond<U>) {
  left.designatedDynamic ->| right
}

public func ->| <T: Dynamical, U: Bondable where T.DynamicType == U.BondType>(left: T, right: U) {
  left.designatedDynamic ->| right.designatedBond
}

public func ->| <T, U: Bondable where U.BondType == T>(left: Dynamic<T>, right: U) {
  left ->| right.designatedBond
}


// MARK: Two way bind

public func <->> <T>(left: Dynamic<T>, right: Dynamic<T>) {
  left.bindTo(right.valueBond, fire: true, strongly: true)
  right.bindTo(left.valueBond, fire: false, strongly: false)
}
