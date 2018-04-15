//: Playground - noun: a place where people can play

import Bond
import ReactiveKit
import PlaygroundSupport

// Play here!

let c = MutableObservableCollection(["a", "b", "c"])

c.observeNext { (event) in
    print(event.collection, "diff:", event.diff, "patch:", event.diff.patch)
}

c.batchUpdate { (c) in
    c.insert("x", at: 0)
    c.move(from: [1, 2], to: 0)
    c.removeAll()
}
