//: Playground - noun: a place where people can play

import Bond
import ReactiveKit
import PlaygroundSupport

// Play here!

let c = MutableObservableCollection(["a", "b", "c", "d", "e"])

c.observeNext { (event) in
    print(event.collection, "diff:", event.diff, "patch:", event.diff.patch)
}

c.batchUpdate { (c) in
    c.moveItem(from: 0, to: 3)
    c.remove(at: 2)
    c.moveItem(from: 2, to: 1)
    c.insert("p", at: 0)
}
