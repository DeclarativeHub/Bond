//: Playground - noun: a place where people can play

import Bond
import ReactiveKit
import PlaygroundSupport

// Play here!

let tree = MutableObservableCollection(TreeNode("Root"))

tree.observeNext { (event) in
    print(event.collection, "diff", event.diff, "patch", event.diff.patch)
}

tree.append(TreeNode("Child A"))
tree.append(TreeNode("Child B"))
tree.insert(TreeNode("Chile X"), at: [0, 0])
