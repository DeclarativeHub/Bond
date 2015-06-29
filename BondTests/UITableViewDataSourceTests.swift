
import UIKit
import Bond
import XCTest

enum TableOperation {
  case BeginUpdates
  case EndUpdates
  case InsertRows([NSIndexPath])
  case DeleteRows([NSIndexPath])
  case ReloadRows([NSIndexPath])
  case InsertSections(NSIndexSet)
  case DeleteSections(NSIndexSet)
  case ReloadSections(NSIndexSet)
  case ReloadData
}

func ==(op0: TableOperation, op1: TableOperation) -> Bool {
  switch (op0, op1) {
  case (.BeginUpdates, .BeginUpdates):
    return true
  case (.EndUpdates, .EndUpdates):
    return true
  case let (.InsertRows(paths0), .InsertRows(paths1)):
    return paths0 == paths1
  case let (.DeleteRows(paths0), .DeleteRows(paths1)):
    return paths0 == paths1
  case let (.ReloadRows(paths0), .ReloadRows(paths1)):
    return paths0 == paths1
  case let (.InsertSections(i0), .InsertSections(i1)):
    return i0.isEqualToIndexSet(i1)
  case let (.DeleteSections(i0), .DeleteSections(i1)):
    return i0.isEqualToIndexSet(i1)
  case let (.ReloadSections(i0), .ReloadSections(i1)):
    return i0.isEqualToIndexSet(i1)
  case (.ReloadData, .ReloadData):
    return true
  default:
    return false
  }
}

func wrapUpdate(op: TableOperation) -> [TableOperation] {
  return [.BeginUpdates, op, .EndUpdates]
}

extension TableOperation: Equatable, Printable {
  var description: String {
    switch self {
    case .BeginUpdates:
      return "BeginUpdates"
    case .EndUpdates:
      return "EndUpdates"
    case let .InsertRows(indexPaths):
      return "InsertRows(\(indexPaths)"
    case let .DeleteRows(indexPaths):
      return "DeleteRows(\(indexPaths)"
    case let .ReloadRows(indexPaths):
      return "ReloadRows(\(indexPaths)"
    case let .InsertSections(indices):
      return "InsertSections(\(indices)"
    case let .DeleteSections(indices):
      return "DeleteSections(\(indices)"
    case let .ReloadSections(indices):
      return "ReloadSections(\(indices)"
    case .ReloadData:
      return "ReloadData"
    }
  }
}

class TestTableView: UITableView {
  var operations = [TableOperation]()
  
  override func beginUpdates() {
    operations.append(.BeginUpdates)
    super.beginUpdates()
  }
  
  override func endUpdates() {
    operations.append(.EndUpdates)
    super.endUpdates()
  }
  
  override func insertRowsAtIndexPaths(indexPaths: [AnyObject], withRowAnimation animation: UITableViewRowAnimation) {
    operations.append(.InsertRows(indexPaths as! [NSIndexPath]))
    super.insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
  }
  
  override func deleteRowsAtIndexPaths(indexPaths: [AnyObject], withRowAnimation animation: UITableViewRowAnimation) {
    operations.append(.DeleteRows(indexPaths as! [NSIndexPath]))
    super.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
  }
  
  override func reloadRowsAtIndexPaths(indexPaths: [AnyObject], withRowAnimation animation: UITableViewRowAnimation) {
    operations.append(.ReloadRows(indexPaths as! [NSIndexPath]))
    super.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
  }
  
  override func insertSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
    operations.append(.InsertSections(sections))
    super.insertSections(sections, withRowAnimation: animation)
  }
  
  override func deleteSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
    operations.append(.DeleteSections(sections))
    super.deleteSections(sections, withRowAnimation: animation)
  }
  
  override func reloadSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
    operations.append(.ReloadSections(sections))
    super.reloadSections(sections, withRowAnimation: animation)
  }
  
  override func reloadData() {
    operations.append(.ReloadData)
    super.reloadData()
  }
}

class UITableViewDataSourceTests: XCTestCase {
  var tableView: TestTableView!
  var array: DynamicArray<DynamicArray<Int>>!
  var bond: UITableViewDataSourceBond<Void>!
  var expectedOperations: [TableOperation]!
  override func setUp() {
    array = DynamicArray([DynamicArray([1, 2]), DynamicArray([3, 4])])
    let tableView = TestTableView()
    self.tableView = tableView
    tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cellID")
    expectedOperations = []
    bond = UITableViewDataSourceBond(tableView: tableView, disableAnimation: true)
    array.map { array, sectionIndex in
      array.map { int, index -> UITableViewCell in
        return tableView.dequeueReusableCellWithIdentifier("cellID") as! UITableViewCell
      }
    } ->> bond
    expectedOperations.append(.ReloadData) // `tableView` will get a `reloadData` when the bond is attached
  }
  
  func testReload() {
    array.setArray([])
    expectedOperations.append(.ReloadData)
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
    
  func testInsertARow() {
    array[1].append(5)
    expectedOperations.extend(wrapUpdate(.InsertRows([NSIndexPath(forRow: 2, inSection: 1)])))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testDeleteARow() {
    array[1].removeLast()
    expectedOperations.extend(wrapUpdate(.DeleteRows([NSIndexPath(forRow: 1, inSection: 1)])))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testReloadARow() {
    array[1][1] = 5
    expectedOperations.extend(wrapUpdate(.ReloadRows([NSIndexPath(forRow: 1, inSection: 1)])))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testInsertASection() {
    array.insert(DynamicArray([7, 8, 9]), atIndex: 1)
    expectedOperations.extend(wrapUpdate(.InsertSections(NSIndexSet(index: 1))))
    XCTAssertEqual(tableView.numberOfRowsInSection(1), 3, "wrong number of rows in new section")
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testDeleteASection() {
    array.removeAtIndex(0)
    expectedOperations.extend(wrapUpdate(.DeleteSections(NSIndexSet(index: 0))))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testReloadASection() {
    array[1] = DynamicArray([5, 6, 7])
    expectedOperations.extend(wrapUpdate(.ReloadSections(NSIndexSet(index: 1))))
    XCTAssertEqual(tableView.numberOfRowsInSection(1), 3, "wrong number of rows in reloaded section")
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testBatchUpdates() {
    array.beginBatchUpdates()
    array[1] = DynamicArray([5, 6, 7, 8])
    array[1].beginBatchUpdates()
    array[1].insert(4, atIndex: 0)
    expectedOperations.extend([
      .BeginUpdates,
      .ReloadSections(NSIndexSet(index: 1)),
      .BeginUpdates,
      .InsertRows([NSIndexPath(forRow: 0, inSection: 1)])
    ])
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
    XCTAssertEqual(tableView.numberOfRowsInSection(1), 2, "wrong number of rows in reloaded section")
    
    array[1].endBatchUpdates()
    XCTAssertEqual(tableView.numberOfRowsInSection(1), 2, "wrong number of rows in reloaded section")
    
    array.endBatchUpdates()
    XCTAssertEqual(tableView.numberOfRowsInSection(1), 5, "wrong number of rows in reloaded section")
    
    expectedOperations.extend([.EndUpdates, .EndUpdates])
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
}
