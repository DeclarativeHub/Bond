//: Playground - noun: a place where people can play

import Bond
import ReactiveKit
import PlaygroundSupport

// Play here!

let t = TreeArray<String>([
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

//tree.observeNext { (event) in
//    print(event.collection, "diff", event.diff, "patch", event.patch)
//}
//
//tree.batchUpdate { (tree) in
////    tree[[0]] = TreeNode<String>("Child X")
////    tree.move(from: [0], to: [0, 0])
////    tree.append(TreeNode<String>("Child Y"))
////    tree.move(from: [0, 0], to: [1])
//}

for n in t {
    print(n)
}
