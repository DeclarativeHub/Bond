//: Playground - noun: a place where people can play

import Bond
import ReactiveKit
import PlaygroundSupport

// Play here!

// Array

let a = MutableObservableArray([1, 2, 3])

a.observeNext { (cs) in
    print(cs.diff, cs.patch)
}

a.batchUpdate { (a) in
    a.append(1)
    a.append(2)
}

// Array2D

let array2D = MutableObservableArray2D(Array2D<String, String>(sectionsWithItems: [
    ("Cities", ["Paris", "Berlin"])
]))

array2D.observeNext { (cs) in
    print(cs.collection, cs.diff, cs.patch)
}

array2D.appendItem("Copenhagen", toSectionAt: 0)

array2D.appendSection("Contries")
array2D.appendItem("France", toSectionAt: 1)

// Set

let s = MutableObservableSet(Set([1, 4, 3]))

s.sortedCollection().mapCollection { $0 * 2 }.filterCollection { $0 > 2 }.observeNext { (changeset) in
    print(changeset.collection, changeset.diff, changeset.patch)
}

s.insert(5)

// Dictionary

let dictionary = MutableObservableDictionary(["A": 1])

dictionary.sortedCollection(by: { $0.key < $1.key }).mapCollection({ "\($0.key): \($0.value)"}).observeNext { (changeset) in
    print(changeset.collection, changeset.diff, changeset.patch)
}

dictionary["B"] = 2

// Custom collection - Data

let data = MutableObservableCollection(Data(bytes: [0x0A, 0x0B]))

data.observeNext { (changeset) in
    print(changeset.collection, changeset.diff, changeset.patch)
}

data.append(0xFF)
data[0] = 0xAA

// Tree array

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

let ot = MutableObservableTree(t)

ot.observeNext { (cs) in
    print(cs.collection, cs.diff, cs.patch)
}

ot.insert(TreeNode("New"), at: [0, 0])

ot.batchUpdate { (ot) in
    ot.remove(at: [0, 0])
    ot.remove(at: [0, 2, 1])
}

ot.insert(contentsOf: [TreeNode("44"), TreeNode("55")], at: [0, 3])
