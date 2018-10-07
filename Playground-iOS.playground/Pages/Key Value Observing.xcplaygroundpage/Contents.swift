//: [Previous](@previous)

import UIKit
import Bond
import ReactiveKit
import PlaygroundSupport

class Contact: NSObject {
    @objc dynamic var name: String? = "n/a"
}

var contact: Contact! = Contact()
weak var weakTest: Contact? = contact

contact.reactive.keyPath(\.name).observeNext { event in
    print(event)
}

contact.name = "jim"
contact.name = nil
contact.name = "james"

SafeSignal.just("j").bind(to: contact, keyPath: \.name, context: .immediate)

contact = nil
assert(weakTest == nil)

//: [Next](@next)
