//: Playground - noun: a place where people can play

import UIKit
import Bond
import ReactiveKit
import PlaygroundSupport

// Turn on the Assistant Editor to see the table view!

let me = UIView()

extension UIView {

  open override var bindingExecutionContext: ExecutionContext {
    return .immediate
  }
}

//: [Next](@next)

