//: Playground - noun: a place where people can play

import Bond
import ReactiveKit
import PlaygroundSupport

// Play here!

let tree = MutableObservableCollection(TreeNode("Root"))

tree.observeNext { (event) in
    print(event.collection, "diff", event.diff, "patch", event.patch)
}

tree.append(TreeNode("Child A"))
tree.append(TreeNode("Child B"))
tree.move(from: [0], to: [1])


//tree.batchUpdate { (tree) in
//    tree[[0]] = TreeNode<String>("Child X")
//    tree.move(from: [0], to: [0, 0])
//    tree.append(TreeNode<String>("Child Y"))
//    tree.move(from: [0, 0], to: [1])
//}
