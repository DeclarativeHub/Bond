//
//  Bond+Operators.swift
//  Bond
//
//  Created by Srđan Rašić on 28/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
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
  left.designatedDynamic() ->> right
}

public func ->> <T: Dynamical, U: Bondable where T.DynamicType == U.BondType>(left: T, right: U) {
  left.designatedDynamic() ->> right.designatedBond
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
  left.designatedDynamic() ->| right
}

public func ->| <T: Dynamical, U: Bondable where T.DynamicType == U.BondType>(left: T, right: U) {
  left.designatedDynamic() ->| right.designatedBond
}

public func ->| <T, U: Bondable where U.BondType == T>(left: Dynamic<T>, right: U) {
  left ->| right.designatedBond
}


// MARK: Two way bind

public func <->> <T>(left: Dynamic<T>, right: Dynamic<T>) {
  left.bindTo(right.valueBond, fire: true, strongly: true)
  right.bindTo(left.valueBond, fire: false, strongly: false)
}
