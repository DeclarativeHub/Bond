
import UIKit
import Bond
import XCTest

enum TableOperation {
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

extension TableOperation: Equatable, CustomStringConvertible {
  var description: String {
    switch self {
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
  override func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
    operations.append(.InsertRows(indexPaths))
    super.insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
  }
  
  override func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
    operations.append(.DeleteRows(indexPaths))
    super.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
  }
  
  override func reloadRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
    operations.append(.ReloadRows(indexPaths))
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
  var array: ObservableArray<ObservableArray<Int>>!
  var expectedOperations: [TableOperation]!
  
  override func setUp() {
    self.array = ObservableArray([ObservableArray([1, 2]), ObservableArray([3, 4])])
    self.tableView = TestTableView()
    
    tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cellID")
    
    expectedOperations = []
    
    array.bindTo(tableView) { (indexPath, array, tableView) -> UITableViewCell in
      let cell = tableView.dequeueReusableCellWithIdentifier("cellID", forIndexPath: indexPath)
      return cell
    }
    
    expectedOperations.append(.ReloadData) // `tableView` will get a `reloadData` when the bond is attached
  }
  
//  func testReload() {
//    array.setArray([])
//    expectedOperations.append(.ReloadData)
//    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
//  }
  
  func testInsertARow() {
    array[1].append(5)
    expectedOperations.append(.InsertRows([NSIndexPath(forRow: 2, inSection: 1)]))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testDeleteARow() {
    array[1].removeLast()
    expectedOperations.append(.DeleteRows([NSIndexPath(forRow: 1, inSection: 1)]))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testReloadARow() {
    array[1][1] = 5
    expectedOperations.append(.ReloadRows([NSIndexPath(forRow: 1, inSection: 1)]))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testInsertASection() {
    array.insert(ObservableArray([7, 8, 9]), atIndex: 1)
    expectedOperations.append(.InsertSections(NSIndexSet(index: 1)))
    XCTAssertEqual(tableView.numberOfRowsInSection(1), 3, "wrong number of rows in new section")
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testDeleteASection() {
    array.removeAtIndex(0)
    expectedOperations.append(.DeleteSections(NSIndexSet(index: 0)))
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
  
  func testReloadASection() {
    array[1] = ObservableArray([5, 6, 7])
    expectedOperations.append(.ReloadSections(NSIndexSet(index: 1)))
    XCTAssertEqual(tableView.numberOfRowsInSection(1), 3, "wrong number of rows in reloaded section")
    XCTAssertEqual(expectedOperations, tableView.operations, "operation sequence did not match")
  }
}
