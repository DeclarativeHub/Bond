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

print(t.depthFirst.map { $0.value })
print(t.breadthFirst.map { $0.value })

print(t.depthFirst.firstIndex(where: { $0.value.hasSuffix("200") })!)
print(t.depthFirst.allSatisfy { $0.value.starts(with: "Child") })
print(t.depthFirst.randomElement()!)

// Tree node is a tree with multiple roots

var ta = TreeArray<String>([
    t,
    TreeNode("Child 01", [
        TreeNode("Child 010")
    ])
])

print(ta.depthFirst.map { $0.value })
print(ta.breadthFirst.map { $0.value })

print(ta.depthFirst.firstIndex(where: { $0.value.hasSuffix("200") })!)
print(t.depthFirst.allSatisfy { $0.value.starts(with: "Child") })
print(t.depthFirst.randomElement()!)

// Custom trees

extension UIView: TreeProtocol {

    public var children: [UIView] {
        return subviews
    }
}

let v = UIPickerView()

print(v.depthFirst.map { type(of: $0) })
print(v.breadthFirst.map { type(of: $0) })

print(v[childAt: [0, 0]])


//: [Next](@next)
