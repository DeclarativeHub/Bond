//: [Previous](@previous)

import Foundation
import UIKit
import Bond

// Tree node is a tree with a single root

var t = TreeNode("Child 00", [
    TreeNode("Child 000"),
    TreeNode("Child 001", [
        TreeNode("Child 0010")
    ]),
    TreeNode("Child 002", [
        TreeNode("Child 0020", [
            TreeNode("Child 00200")
        ]),
        TreeNode("Child 0021")
    ])
])

print(t.dfsView.map { $0.value })
print(t.bfsView.map { $0.value })

print(t.dfsView.firstIndex(where: { $0.value.hasSuffix("200") })!)
print(t.dfsView.allSatisfy { $0.value.starts(with: "Child") })
print(t.dfsView.randomElement()!)

// Tree node is a tree with multiple roots

var ta = TreeArray<String>([
    t,
    TreeNode("Child 01", [
        TreeNode("Child 010")
    ])
])

print(ta.dfsView.map { $0.value })
print(ta.bfsView.map { $0.value })

print(ta.dfsView.firstIndex(where: { $0.value.hasSuffix("200") })!)
print(t.dfsView.allSatisfy { $0.value.starts(with: "Child") })
print(t.dfsView.randomElement()!)

// Custom trees

extension UIView: TreeProtocol {

    public var children: [UIView] {
        return subviews
    }
}

let v = UIPickerView()

print(v.dfsView.map { type(of: $0) })
print(v.bfsView.map { type(of: $0) })

print(v[childAt: [0, 0]])


//: [Next](@next)
