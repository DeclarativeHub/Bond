//: [Previous](@previous)

import UIKit
import Bond
import ReactiveKit
import PlaygroundSupport

class Test: NSObject {
    dynamic var test: String! = "0"
}

var test: Test! = Test()
weak var weakTest: Test? = test

test.keyPath("test", ofType: Optional<String>.self).observe { event in
    print(event)
}

test.test = "a"
test.test = nil
test.test = "g"

Signal1.just("c").bind(to: test.keyPath("test", ofType: Optional<String>.self))

test = nil
weakTest

//: [Next](@next)
