//
//  Bond+Functional.swift
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

// MARK: Map

public func map<T, U>(dynamic: Dynamic<T>, f: T -> U) -> Dynamic<U> {
  return _map(dynamic, f)
}

public func map<S: Dynamical, T, U where S.DynamicType == T>(dynamical: S, f: T -> U) -> Dynamic<U> {
  return _map(dynamical.designatedDynamic, f)
}

internal func _map<T, U>(dynamic: Dynamic<T>, f: T -> U) -> Dynamic<U> {
  let dyn = InternalDynamic<U>(f(dynamic.value), faulty: dynamic.faulty)
  
  let bond = Bond<T> { [unowned dyn] t in
    dyn.value = f(t)
  }
  
  dyn.retain(bond)
  dynamic.bindTo(bond, fire: false)
  
  return dyn
}

// MARK: Filter

public func filter<T>(dynamic: Dynamic<T>, f: T -> Bool) -> Dynamic<T> {
  return _filter(dynamic, f)
}

public func filter<T>(dynamic: Dynamic<T>, f: (T, T) -> Bool, v: T) -> Dynamic<T> {
  return _filter(dynamic) { f($0, v) }
}

public func filter<S: Dynamical, T where S.DynamicType == T>(dynamical: S, f: T -> Bool) -> Dynamic<T> {
  return _filter(dynamical.designatedDynamic, f)
}

internal func _filter<T>(dynamic: Dynamic<T>, f: T -> Bool) -> Dynamic<T> {
  let value = dynamic.value
  let dyn = InternalDynamic<T>(value, faulty: dynamic.faulty || !f(value))
  
  let bond = Bond<T> { [unowned dyn] t in
    if f(t) {
      dyn.value = t
    }
  }
  
  dyn.retain(bond)
  dynamic.bindTo(bond, fire: false)
  
  return dyn
}

// MARK: Reduce

public func reduce<A, B, T>(dA: Dynamic<A>, dB: Dynamic<B>, f: (A, B) -> T) -> Dynamic<T> {
  return _reduce(dA, dB, f(dA.value, dB.value), f)
}

public func reduce<A, B, T>(dA: Dynamic<A>, dB: Dynamic<B>, v0: T, f: (A, B) -> T) -> Dynamic<T> {
  return _reduce(dA, dB, v0, f)
}

public func reduce<A, B, C, T>(dA: Dynamic<A>, dB: Dynamic<B>, dC: Dynamic<C>, v0: T, f: (A, B, C) -> T) -> Dynamic<T> {
  return _reduce(dA, dB, dC, v0, f)
}

public func reduce<A, B, C, T>(dA: Dynamic<A>, dB: Dynamic<B>, dC: Dynamic<C>, f: (A, B, C) -> T) -> Dynamic<T> {
  return _reduce(dA, dB, dC, f(dA.value, dB.value, dC.value), f)
}

public func _reduce<A, B, T>(dA: Dynamic<A>, dB: Dynamic<B>, v0: T, f: (A, B) -> T) -> Dynamic<T> {
  let dyn = InternalDynamic<T>(v0, faulty: dA.faulty || dB.faulty)
  
  let bA = Bond<A> { [unowned dyn, weak dB] in
    if let dB = dB { dyn.value = f($0, dB.value) }
  }
  
  let bB = Bond<B> { [unowned dyn, weak dA] in
    if let dA = dA { dyn.value = f(dA.value, $0) }
  }
  
  dA.bindTo(bA, fire: false)
  dB.bindTo(bB, fire: false)
  
  dyn.retain(bA)
  dyn.retain(bB)
  
  return dyn
}

internal func _reduce<A, B, C, T>(dA: Dynamic<A>, dB: Dynamic<B>, dC: Dynamic<C>, v0: T, f: (A, B, C) -> T) -> Dynamic<T> {
  let dyn = InternalDynamic<T>(v0, faulty: dA.faulty || dB.faulty || dC.faulty)
  
  let bA = Bond<A> { [unowned dyn, weak dB, weak dC] in
    if let dB = dB { if let dC = dC { dyn.value = f($0, dB.value, dC.value) } }
  }
  
  let bB = Bond<B> { [unowned dyn, weak dA, weak dC] in
    if let dA = dA { if let dC = dC { dyn.value = f(dA.value, $0, dC.value) } }
  }
  
  let bC = Bond<C> { [unowned dyn, weak dA, weak dB] in
    if let dA = dA { if let dB = dB { dyn.value = f(dA.value, dB.value, $0) } }
  }
  
  dA.bindTo(bA, fire: false)
  dB.bindTo(bB, fire: false)
  dC.bindTo(bC, fire: false)
  
  dyn.retain(bA)
  dyn.retain(bB)
  dyn.retain(bC)
  
  return dyn
}

// MARK: Rewrite

public func rewrite<T, U>(dynamic: Dynamic<T>, value: U) -> Dynamic<U> {
  return _map(dynamic) { _ in value }
}

// MARK: Zip

public func zip<T, U>(dynamic: Dynamic<T>, value: U) -> Dynamic<(T, U)> {
  return _map(dynamic) { ($0, value) }
}

public func zip<T, U>(d1: Dynamic<T>, d2: Dynamic<U>) -> Dynamic<(T, U)> {
  return reduce(d1, d2) { ($0, $1) }
}

// MARK: Skip

class SkipDynamic<T>: InternalDynamic<T> {
  var count: Int
  
  init(_ v: T, count: Int) {
    self.count = count
    super.init(v, faulty: count > 0)
  }
}

public func _skip<T>(dynamic: Dynamic<T>, count: Int) -> Dynamic<T> {
  let dyn = SkipDynamic<T>(dynamic.value, count: count)
  
  let bond = Bond<T> { [unowned dyn] t in
    if dyn.count <= 0 {
      dyn.value = t
    } else {
      dyn.count--
    }
  }
  
  dyn.retain(bond)
  dynamic.bindTo(bond, fire: false)
  
  return dyn
}

public func skip<T>(dynamic: Dynamic<T>, count: Int) -> Dynamic<T> {
  return _skip(dynamic, count)
}

// MARK: Any

public func any<T>(dynamics: [Dynamic<T>]) -> Dynamic<T> {
  if dynamics.count < 1 {
    fatalError("Must provide at least one Dynamic!")
  }
  
  let dyn = InternalDynamic<T>(dynamics.first!.value, faulty: true)
  
  for dynamic in dynamics {
    let bond = Bond<T> { [unowned dynamic] in
      dyn.value = $0
    }
    dynamic.bindTo(bond, fire: false)
    dyn.retain(bond)
  }
  
  return dyn
}
