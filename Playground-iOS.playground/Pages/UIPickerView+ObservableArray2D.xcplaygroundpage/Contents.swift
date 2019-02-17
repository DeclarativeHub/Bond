//: [Previous](@previous)

import Foundation
import PlaygroundSupport
import UIKit
import Bond
import ReactiveKit

let pickerView = UIPickerView()
pickerView.frame.size = CGSize(width: 300, height: 300)
pickerView.backgroundColor = .white

// Note: Open the assistant editor to see the table view
PlaygroundPage.current.liveView = pickerView
PlaygroundPage.current.needsIndefiniteExecution = true

let data = MutableObservableArray2D(
    Array2D<String, String>(
        sectionsWithItems: [
            ("Feet", ["0 ft", "1 ft", "2 ft", "3 ft", "4 ft", "5 ft", "6 ft", "7 ft", "8 ft", "9 ft"]),
            ("Inches", ["0 in", "1 in", "2 in", "3 in", "4 in", "5 in", "6 in", "7 in", "8 in", "9 in", "10 in", "11 in", "12 in"])
        ]
    )
)

data.bind(to: pickerView)

// Handle cell selection
let selectedRow = pickerView.reactive.selectedRow

selectedRow.observeNext { (row, component) in
    print("selected", row, component)
}

let selectedPair = selectedRow.scan([0, 0]) { (pair, rowAndComponent) -> [Int] in
    var pair = pair
    pair[rowAndComponent.1] = rowAndComponent.0
    return pair
}

selectedPair.observeNext { (pair) in
    print("selected indices", pair)
    let items = pair.enumerated().map {
        data[itemAt: [$0.offset, $0.element]]
    }
    print("selected items", items)
}

//: [Next](@next)
