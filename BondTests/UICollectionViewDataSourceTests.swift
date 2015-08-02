
import UIKit
import Bond
import XCTest

enum CollectionOperation {
  case BeginUpdates
  case EndUpdates
  case InsertItems([NSIndexPath])
  case DeleteItems([NSIndexPath])
  case ReloadItems([NSIndexPath])
  case InsertSections(NSIndexSet)
  case DeleteSections(NSIndexSet)
  case ReloadSections(NSIndexSet)
  case ReloadData
}

func ==(op0: CollectionOperation, op1: CollectionOperation) -> Bool {
  switch (op0, op1) {
  case (.BeginUpdates, .BeginUpdates):
    return true
  case (.EndUpdates, .EndUpdates):
    return true
  case let (.InsertItems(paths0), .InsertItems(paths1)):
    return paths0 == paths1
  case let (.DeleteItems(paths0), .DeleteItems(paths1)):
    return paths0 == paths1
  case let (.ReloadItems(paths0), .ReloadItems(paths1)):
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

func wrapUpdate(ops: CollectionOperation...) -> [CollectionOperation] {
  return [.BeginUpdates] + ops + [.EndUpdates]
}

extension CollectionOperation: Equatable, Printable {
  var description: String {
    switch self {
    case .BeginUpdates:
      return "BeginUpdates"
    case .EndUpdates:
      return "EndUpdates"
    case let .InsertItems(indexPaths):
      return "InsertItems(\(indexPaths)"
    case let .DeleteItems(indexPaths):
      return "DeleteItems(\(indexPaths)"
    case let .ReloadItems(indexPaths):
      return "ReloadItems(\(indexPaths)"
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

class TestCollectionView: UICollectionView {
  var operations = [CollectionOperation]()
  var onceBatchUpdatesCompleted: ((Bool) -> ())?
  
  override func performBatchUpdates(updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
    operations.append(.BeginUpdates)
    super.performBatchUpdates(updates, completion: { (finished) -> Void in
      self.operations.append(.EndUpdates)
      completion?(finished)
      self.onceBatchUpdatesCompleted?(finished)
      self.onceBatchUpdatesCompleted = nil
    })
  }
  
  override func insertItemsAtIndexPaths(indexPaths: [AnyObject]) {
    operations.append(.InsertItems(indexPaths as! [NSIndexPath]))
    super.insertItemsAtIndexPaths(indexPaths)
  }
  
  override func deleteItemsAtIndexPaths(indexPaths: [AnyObject]) {
    operations.append(.DeleteItems(indexPaths as! [NSIndexPath]))
    super.deleteItemsAtIndexPaths(indexPaths)
  }
  
  override func reloadItemsAtIndexPaths(indexPaths: [AnyObject]) {
    operations.append(.ReloadItems(indexPaths as! [NSIndexPath]))
    super.reloadItemsAtIndexPaths(indexPaths)
  }
  
  override func insertSections(sections: NSIndexSet) {
    operations.append(.InsertSections(sections))
    super.insertSections(sections)
  }
  
  override func deleteSections(sections: NSIndexSet) {
    operations.append(.DeleteSections(sections))
    super.deleteSections(sections)
  }
  
  override func reloadSections(sections: NSIndexSet) {
    operations.append(.ReloadSections(sections))
    super.reloadSections(sections)
  }
  
  override func reloadData() {
    operations.append(.ReloadData)
    super.reloadData()
  }
}

// TODO: Add test for mixed section & object updates

class UICollectionViewDataSourceTests: XCTestCase {
  var collectionView: TestCollectionView!
  var array: DynamicArray<DynamicArray<Int>>!
  var bond: UICollectionViewDataSourceBond<Void>!
  var expectedOperations: [CollectionOperation]!
  override func setUp() {
    array = DynamicArray([DynamicArray([1, 2]), DynamicArray([3, 4])])
    let collectionView = TestCollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    self.collectionView = collectionView
    collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "cellID")
    expectedOperations = []
    bond = UICollectionViewDataSourceBond(collectionView: collectionView)
    array.map { array, sectionIndex in
      array.map { int, index -> UICollectionViewCell in
        return collectionView.dequeueReusableCellWithReuseIdentifier("cellID", forIndexPath: NSIndexPath(forItem: index, inSection: sectionIndex)) as! UICollectionViewCell
      }
    } ->> bond
    expectedOperations.append(.ReloadData) // `tableView` will get a `reloadData` when the bond is attached
    
    // NOTE: Force collectionView to actually load items in section so that later tests do not fail
    // with NSInconsistency exception related to InvalidUpdate
    // http://stackoverflow.com/questions/13392413/uicollectionview-insertitemsatindexpaths-throws-exception
    XCTAssertEqual(collectionView.numberOfSections(), 2, "2 sections before set")
    collectionView.numberOfItemsInSection(0)
  }
  
  func testReload() {
    collectionView.reloadData()
    expectedOperations.append(.ReloadData)
    XCTAssertEqual(expectedOperations, collectionView.operations, "operation sequence did not match")

    let e = expectationWithDescription("batchComplete")
    collectionView.performBatchUpdates({
        self.collectionView.reloadData()
    }, completion: { finished in
      XCTAssertEqual(self.expectedOperations, self.collectionView.operations, "operation sequence did not match")
      e.fulfill()
    })
    
    // NOTE: UICollectionView internally calls ReloadData once after batchUpdates if reloadData is called from within batchUpdates
    expectedOperations.extend(wrapUpdate(.ReloadData, .ReloadData))
    waitForExpectationsWithTimeout(1, handler: nil)
  }
  
  func testReloadViaDynamicArray() {
    array.setArray([])
    // NOTE: UICollectionView internally calls ReloadData once after batchUpdates if reloadData is called from within batchUpdates
    expectedOperations.extend([.ReloadData])
    XCTAssertEqual(self.expectedOperations, self.collectionView.operations, "operation sequence did not match")
  }

  func testInsertAItem() {
    array[1].append(5)
    expectedOperations.extend([.BeginUpdates, .InsertItems([NSIndexPath(forItem: 2, inSection: 1)])])
    XCTAssertEqual(expectedOperations, collectionView.operations, "operation sequence did not match")
    XCTAssertEqual(collectionView.numberOfItemsInSection(1), 3, "items count incorrect")
  }

  func testDeleteAItem() {
    array[1].removeLast()
    expectedOperations.extend([.BeginUpdates, .DeleteItems([NSIndexPath(forItem: 1, inSection: 1)])])
    XCTAssertEqual(expectedOperations, collectionView.operations, "operation sequence did not match")
    XCTAssertEqual(collectionView.numberOfItemsInSection(1), 1, "items count incorrect")
  }

  func testReloadAItem() {
    array[1][1] = 5
    expectedOperations.extend([.BeginUpdates, .ReloadItems([NSIndexPath(forItem: 1, inSection: 1)])])
    XCTAssertEqual(expectedOperations, collectionView.operations, "operation sequence did not match")
  }

  func testInsertASection() {
    array.insert(DynamicArray([7, 8, 9]), atIndex: 1)
    expectedOperations.extend([.BeginUpdates, .InsertSections(NSIndexSet(index: 1))])
    XCTAssertEqual(collectionView.numberOfItemsInSection(1), 3, "wrong number of Items in new section")
    XCTAssertEqual(expectedOperations, collectionView.operations, "operation sequence did not match")
  }

  func testDeleteASection() {
    array.removeAtIndex(0)
    expectedOperations.extend([.BeginUpdates, .DeleteSections(NSIndexSet(index: 0))])
    XCTAssertEqual(expectedOperations, collectionView.operations, "operation sequence did not match")
  }

  func testReloadASection() {
    array[1] = DynamicArray([5, 6, 7])
    expectedOperations.extend([.BeginUpdates, .ReloadSections(NSIndexSet(index: 1))])
    XCTAssertEqual(collectionView.numberOfItemsInSection(1), 3, "wrong number of Items in reloaded section")
    XCTAssertEqual(expectedOperations, collectionView.operations, "operation sequence did not match")
  }

  func testBatchUpdates() {
    array.beginBatchUpdates()
    array[1] = DynamicArray([5, 6, 7, 8])
    array[1].beginBatchUpdates()
    array[1].insert(4, atIndex: 0)
    XCTAssertEqual(expectedOperations, collectionView.operations, "operation sequence did not match")
    XCTAssertEqual(collectionView.numberOfItemsInSection(1), 2, "wrong number of Items in reloaded section")
    
    array[1].endBatchUpdates()
    XCTAssertEqual(collectionView.numberOfItemsInSection(1), 2, "wrong number of Items in reloaded section")
    
    array.endBatchUpdates()
    expectedOperations.extend([
      .BeginUpdates,
      .ReloadSections(NSIndexSet(index: 1)),
      .InsertItems([NSIndexPath(forItem: 0, inSection: 1)])
    ])
    XCTAssertEqual(collectionView.numberOfItemsInSection(1), 5, "wrong number of Items in reloaded section")
    XCTAssertEqual(expectedOperations, collectionView.operations, "operation sequence did not match")
    
    let e = expectationWithDescription("End Updates")
    expectedOperations.extend([.EndUpdates])
    collectionView.onceBatchUpdatesCompleted = { _ in
        XCTAssertEqual(self.expectedOperations, self.collectionView.operations, "operation sequence did not match")
      e.fulfill()
    }
    waitForExpectationsWithTimeout(1, handler: nil)
  }
}
