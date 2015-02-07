//
//  Bond.swift
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

// MARK: Helpers

public class BondBox<T> {
  weak var bond: Bond<T>?
  public init(_ b: Bond<T>) { bond = b }
}

// MARK: - Scalar Dynamic

// MARK: Bond

public class Bond<T> {
  public typealias Listener = T -> Void
  public var listener: Listener?
  public var bondedDynamics: [Dynamic<T>] = []
  
  public init() {
  }
  
  public init(_ listener: Listener) {
    self.listener = listener
  }
  
  public func bind(dynamic: Dynamic<T>, fire: Bool = true) {
    dynamic.bonds.append(BondBox(self))
    self.bondedDynamics.append(dynamic)
    if fire {
      self.listener?(dynamic.value)
    }
  }
  
  public func unbindAll() {
    for dynamic in bondedDynamics {
      var bondsToKeep: [BondBox<T>] = []
      for bondBox in dynamic.bonds {
        if let bond = bondBox.bond {
          if bond !== self {
            bondsToKeep.append(bondBox)
          } else {
            
          }
        }
      }
      dynamic.bonds = bondsToKeep
    }
    
    self.bondedDynamics.removeAll(keepCapacity: true)
  }
}

// MARK: Dynamic

public class Dynamic<T> {
  
  public var value: T {
    didSet {
      
      // clear weak bonds
      bonds = bonds.filter {
        bondBox in bondBox.bond != nil
      }
      
      // notify
      for bondBox in bonds {
        bondBox.bond?.listener?(value)
      }
    }
  }
  
  public var bonds: [BondBox<T>] = []

  public init(_ v: T) {
    value = v
  }
}

// MARK: Dynamic additions

public extension Dynamic
{
  public func map<U>(f: T -> U) -> Dynamic<U> {
    return _map(self, f)
  }
  
  public func filter(f: T -> Bool) -> Dynamic<T> {
    return _filter(self, f)
  }
}

// MARK: Protocols

public protocol Dynamical {
  typealias DynamicType
  func designatedDynamic() -> Dynamic<DynamicType>
}

public protocol Bondable {
  typealias BondType
  var designatedBond: Bond<BondType> { get }
}

// MARK: - Functional paradigm

public class DynamicExtended<T>: Dynamic<T> {
  
  public override init(_ v: T) {
    super.init(v)
  }
  
  internal var retainedObjects: [AnyObject] = []
  internal func retain(object: AnyObject) {
    retainedObjects.append(object)
  }
}

// MARK: Map

public func map<T, U>(dynamic: Dynamic<T>, f: T -> U) -> Dynamic<U> {
  return _map(dynamic, f)
}

public func map<S: Dynamical, T, U where S.DynamicType == T>(dynamical: S, f: T -> U) -> Dynamic<U> {
  return _map(dynamical.designatedDynamic(), f)
}

private func _map<T, U>(dynamic: Dynamic<T>, f: T -> U) -> Dynamic<U> {
  let dyn = DynamicExtended<U>(f(dynamic.value))
  let bond = Bond<T> { [unowned dyn] t in dyn.value = f(t) }
  bond.bind(dynamic)
  dyn.retain(bond)
  return dyn
}

// MARK: Filter

public func filter<T>(dynamic: Dynamic<T>, f: T -> Bool) -> Dynamic<T> {
  return _filter(dynamic, f)
}

public func filter<S: Dynamical, T where S.DynamicType == T>(dynamical: S, f: T -> Bool) -> Dynamic<T> {
  return _filter(dynamical.designatedDynamic(), f)
}

private func _filter<T>(dynamic: Dynamic<T>, f: T -> Bool) -> Dynamic<T> {
  let dyn = DynamicExtended<T>(dynamic.value) // TODO FIX INITAL
  let bond = Bond<T> { [unowned dyn] t in if f(t) { dyn.value = t } }
  bond.bind(dynamic)
  dyn.retain(bond)
  return dyn
}

// MARK: Reduce

public func reduce<A: Dynamical, B: Dynamical, T>(a: A, b: B, v0: T, f: (A.DynamicType, B.DynamicType) -> T) -> Dynamic<T> {
  return _reduce(a.designatedDynamic(), b.designatedDynamic(), v0, f)
}

public func reduce<A: Dynamical, B: Dynamical, C: Dynamical, T>(a: A, b: B, c: C, v0: T, f: (A.DynamicType, B.DynamicType, C.DynamicType) -> T) -> Dynamic<T> {
  return _reduce(a.designatedDynamic(), b.designatedDynamic(), c.designatedDynamic(), v0, f)
}

public func reduce<A, B, T>(dA: Dynamic<A>, dB: Dynamic<B>, v0: T, f: (A, B) -> T) -> Dynamic<T> {
  return _reduce(dA, dB, v0, f)
}

public func reduce<A, B, C, T>(dA: Dynamic<A>, dB: Dynamic<B>, dC: Dynamic<C>, v0: T, f: (A, B, C) -> T) -> Dynamic<T> {
  return _reduce(dA, dB, dC, v0, f)
}

private func _reduce<A, B, T>(dA: Dynamic<A>, dB: Dynamic<B>, v0: T, f: (A, B) -> T) -> Dynamic<T> {
  let dyn = DynamicExtended<T>(v0)
  
  let bA = Bond<A> { [unowned dyn, weak dB] in
    if let dB = dB { dyn.value = f($0, dB.value) }
  }
  
  let bB = Bond<B> { [unowned dyn, weak dA] in
    if let dA = dA { dyn.value = f(dA.value, $0) }
  }
  
  bA.bind(dA)
  bB.bind(dB)
  
  dyn.retain(bA)
  dyn.retain(bB)
  
  return dyn
}

private func _reduce<A, B, C, T>(dA: Dynamic<A>, dB: Dynamic<B>, dC: Dynamic<C>, v0: T, f: (A, B, C) -> T) -> Dynamic<T> {
  let dyn = DynamicExtended<T>(v0)
  
  let bA = Bond<A> { [unowned dyn, weak dB, weak dC] in
    if let dB = dB { if let dC = dC { dyn.value = f($0, dB.value, dC.value) } }
  }
  
  let bB = Bond<B> { [unowned dyn, weak dA, weak dC] in
    if let dA = dA { if let dC = dC { dyn.value = f(dA.value, $0, dC.value) } }
  }
  
  let bC = Bond<C> { [unowned dyn, weak dA, weak dB] in
    if let dA = dA { if let dB = dB { dyn.value = f(dA.value, dB.value, $0) } }
  }
  
  bA.bind(dA)
  bB.bind(dB)
  bC.bind(dC)
  
  dyn.retain(bA)
  dyn.retain(bB)
  dyn.retain(bC)
  
  return dyn
}

// MARK: Operators

// Bind and fire

infix operator ->> { associativity left precedence 105 }

public func ->> <T>(left: Dynamic<T>, right: Bond<T>) {
  right.bind(left)
}

public func ->> <T>(left: Dynamic<T>, right: T -> Void) -> Bond<T> {
  let bond = Bond<T>(right)
  bond.bind(left)
  return bond
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

// Bind only

infix operator ->| { associativity left precedence 105 }

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


