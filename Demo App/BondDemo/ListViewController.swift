//
//  ViewController.swift
//  BondDemo
//
//  Created by Srđan Rašić on 26/01/15.
//  Copyright (c) 2015 Srdan Rasic. All rights reserved.
//

import UIKit
import Bond

class ListViewController: UITableViewController {
  
  var listViewModel: ListViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // setup refresh controll to load next set of repositories
    let refreshControl = UIRefreshControl()
    self.tableView.addSubview(refreshControl)
    refreshControl.addTarget(self, action: Selector("loadNextSet:"), forControlEvents: UIControlEvents.ValueChanged)
    
    // create view model
    listViewModel = ListViewModel(githubApi: "https://api.github.com/repositories")

    // establish a bond between view model and table view
    listViewModel.repositoryCellViewModels.map { [unowned self] (viewModel: ListCellViewModel) -> ListCellView in
      let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as ListCellView
      viewModel.name ->> cell.nameLabel
      viewModel.username ->> cell.ownerLabel
      viewModel.photo ->> cell.avatarImageView
      return cell
    } ->> self.tableView
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    listViewModel.fetchNextPageOfRepositories() {}
  }
  
  func loadNextSet(refreshControl: UIRefreshControl) {
    listViewModel.fetchNextPageOfRepositories() {
      refreshControl.endRefreshing()
    }
  }
}

