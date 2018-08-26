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

let tree = MutableObservableCollection(t)

tree.observeNext { (event) in
    print(event.collection, "diff", event.diff, "patch", event.patch)
}

tree.batchUpdate { (tree) in
//    tree[[0]].value = "Ohoho" //TreeNode<String>("Child X")
    tree.append(TreeNode<String>("Child Y"))
    tree.move(from: [0, 2], to: [2, 0])
//    tree.move(from: [0, 1], to: [1])
}
