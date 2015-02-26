//
//  Bond+UITableView.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

@objc class TableViewDynamicArrayDataSource: NSObject, UITableViewDataSource {
  var dynamic: DynamicArray<UITableViewCell>
  
  init(dynamic: DynamicArray<UITableViewCell>) {
    self.dynamic = dynamic
    super.init()
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.dynamic.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    return self.dynamic[indexPath.item]
  }
}

public class TableViewBond<T>: ArrayBond<UITableViewCell> {
  weak var tableView: UITableView?
  var dataSource: TableViewDynamicArrayDataSource?
  
  init(tableView: UITableView) {
    self.tableView = tableView
    super.init()
    
    self.insertListener = { i in
      self.tableView?.beginUpdates()
      self.tableView?.insertRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: 0) },
        withRowAnimation: UITableViewRowAnimation.Automatic)
      self.tableView?.endUpdates()
    }
    
    self.removeListener = { i, o in
      self.tableView?.beginUpdates()
      self.tableView?.deleteRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: 0) },
        withRowAnimation: UITableViewRowAnimation.Automatic)
      self.tableView?.endUpdates()
    }
    
    self.updateListener = { i in
      self.tableView?.beginUpdates()
      self.tableView?.reloadRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: 0) },
        withRowAnimation: UITableViewRowAnimation.Automatic)
      self.tableView?.endUpdates()
    }
  }
  
  public override func bind(dynamic: Dynamic<Array<UITableViewCell>>, fire: Bool, strongly: Bool) {
    super.bind(dynamic, fire: false, strongly: strongly)
    if let dynamic = dynamic as? DynamicArray {
      dataSource = TableViewDynamicArrayDataSource(dynamic: dynamic)
      tableView?.dataSource = dataSource
      tableView?.reloadData()
    }
  }
}

private var designatedBondHandleUITableView: UInt8 = 0;

extension UITableView /*: Bondable */ {
  public var dataSourceBond: Bond<Array<UITableViewCell>> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUITableView) {
      return (b as? TableViewBond<UITableViewCell>)!
    } else {
      let b = TableViewBond<UITableViewCell>(tableView: self)
      objc_setAssociatedObject(self, &designatedBondHandleUITableView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var designatedBond: Bond<Array<UITableViewCell>> {
    return self.dataSourceBond
  }
}

public func ->> (left: Dynamic<Array<UITableViewCell>>, right: UITableView) {
  left ->> right.designatedBond
}
