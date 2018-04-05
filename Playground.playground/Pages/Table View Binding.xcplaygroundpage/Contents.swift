//: Playground - noun: a place where people can play

import UIKit
import Bond
import ReactiveKit
import PlaygroundSupport

// Play here!

let d = ["a": 1, "c": 3]
let i = d.index(forKey: "b")!

let s = SafeSignal<ObservableCollectionEvent<[String: Int]>>.sequence([
    ObservableCollectionEvent<[String: Int]>.init(collection: ["a": 1, "c": 3], diff: []),
    ObservableCollectionEvent<[String: Int]>.init(collection: d, diff: [.insert(at: i)])
])

s.sortedCollection(by: { $0.1 > $1.1 }).observeNext { e in
    print(e)
}
