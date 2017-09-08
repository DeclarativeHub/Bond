//: Playground - noun: a place where people can play

import UIKit
import Bond
import ReactiveKit
import PlaygroundSupport

// Turn on the Assistant Editor to see the table view!

let p = Property<Int>(2)

_ = p.observeNext { (value) in
    print(value)
}

//: [Next](@next)

