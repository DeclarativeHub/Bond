//: Playground - noun: a place where people can play

import Bond
import ReactiveKit
import PlaygroundSupport

// Play here!

var t = TreeArray<String>([
    TreeNode("Child 00", [
        TreeNode("Child 000"),
        TreeNode("Child 001"),
        TreeNode("Child 002", [
            TreeNode("Child 0020"),
            TreeNode("Child 0021")
        ])
    ]),
    TreeNode("Child 01")
])

let ot = MutableObservableTreeArray(t)

ot.observeNext { (cs) in
    print(cs.diff, cs.patch)
}

ot.insert(TreeNode("New"), at: [0, 0])

ot.batchUpdate { (ot) in
    ot.remove(at: [0, 0])
    ot.remove(at: [0, 2, 1])
}

let a = MutableObservableArray([1, 2, 3])

a.observeNext { (cs) in
    print(cs.diff, cs.patch)
}

a.batchUpdate { (a) in
    a.append(1)
    a.append(2)
}
