//: Playground - noun: a place where people can play

import AppKit
import Bond
import ReactiveKit
import PlaygroundSupport

// Play here!

let c = MutableObservableCollection(["a", "b", "c", "d", "e"])

c.observeNext { (event) in
    print(event.collection, "diff:", event.diff, "patch:", event.diff.patch)
}

c.batchUpdate { (c) in
    c.remove(at: 0)
    c.insert("o", at: 1)
    c.append("z")
    c.removeLast()
}
