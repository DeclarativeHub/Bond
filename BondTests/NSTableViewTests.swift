//
//  NSTableViewTests.swift
//  Bond
//
//  Created by Michail Pishchagin on 15/08/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

enum TableOperation {
  case InsertRows(NSIndexSet)
  case RemoveRows(NSIndexSet)
  case ReloadRows(NSIndexSet, NSIndexSet)
  case ReloadData
}

func ==(op0: TableOperation, op1: TableOperation) -> Bool {
  switch (op0, op1) {
  case let (.InsertRows(set0), .InsertRows(set1)):
    return set0 == set1
  case let (.RemoveRows(set0), .RemoveRows(set1)):
    return set0 == set1
  case let (.ReloadRows(setRows0, setColumns0), .ReloadRows(setRows1, setColumns1)):
    return setRows0 == setRows1 && setColumns0 == setColumns1
  case (.ReloadData, .ReloadData):
    return true
  default:
    return false
  }
}

extension TableOperation: Equatable, CustomStringConvertible {
  var description: String {
    switch self {
    case let .InsertRows(indexSet):
      return "InsertRows(\(indexSet)"
    case let .RemoveRows(indexSet):
      return "RemoveRows(\(indexSet)"
    case let .ReloadRows(rowsSet, columnsSet):
      return "ReloadRows(\(rowsSet), \(columnsSet)"
    case .ReloadData:
      return "ReloadData"
    }
  }
}

class TestTableView: NSTableView {
  var operations = [TableOperation]()
  override func insertRowsAtIndexes(indexes: NSIndexSet, withAnimation animationOptions: NSTableViewAnimationOptions) {
    operations.append(.InsertRows(indexes))
    super.insertRowsAtIndexes(indexes, withAnimation: animationOptions)
  }

  override func removeRowsAtIndexes(indexes: NSIndexSet, withAnimation animationOptions: NSTableViewAnimationOptions) {
    operations.append(.RemoveRows(indexes))
    super.removeRowsAtIndexes(indexes, withAnimation: animationOptions)
  }

  override func reloadDataForRowIndexes(rowIndexes: NSIndexSet, columnIndexes: NSIndexSet) {
    operations.append(.ReloadRows(rowIndexes, columnIndexes))
    super.reloadDataForRowIndexes(rowIndexes, columnIndexes: columnIndexes)
  }

  override func reloadData() {
    operations.append(.ReloadData)
    super.reloadData()
  }
}

class TestTableViewDelegate: BNDTableViewDelegate {
  @objc func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    fatalError("should be unused in tests, as we never show the NSTableView")
  }

  func createCell(row: Int, array: ObservableArray<Int>, tableView: NSTableView) -> NSTableCellView {
    fatalError("should be unused in tests, as we never show the NSTableView")
  }
}

class NSTableViewDataSourceTests: XCTestCase {
  var tableView: TestTableView!
  var delegate: TestTableViewDelegate!
  var array: ObservableArray<Int>!
  var expectedOperations: [TableOperation]!

  override func setUp() {
    self.array = ObservableArray([1, 2])
    self.tableView = TestTableView()
    self.delegate = TestTableViewDelegate()

    expectedOperations = []

    array.bindTo(tableView, delegate: delegate)

    expectedOperations.append(.ReloadData)  // `tableView` will get a `reloadData` when the bond is attached
  }

//  func testReload() {
//    array.value = []
//    expectedOperations.append(.ReloadData)
//    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
//  }

  func testInsertARow() {
    array.append(3)
    expectedOperations.append(.InsertRows(NSIndexSet(index: 2)))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }

  func testDeleteARow() {
    array.removeLast()
    expectedOperations.append(.RemoveRows(NSIndexSet(index: 1)))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }

  func testReloadARow() {
    array[1] = 5
    expectedOperations.append(.ReloadRows(NSIndexSet(index: 1), NSIndexSet()))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
}
