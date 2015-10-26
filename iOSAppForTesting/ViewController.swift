//
//  ViewController.swift
//  iOSAppForTesting
//
//  Created by Anthony Egerton on 15/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import Bond

class ViewController: UIViewController,BNDTableViewProxyDelegate {

    @IBOutlet weak var textField: UITextField!
  
    @IBOutlet weak var textView: UITextView!
  
    @IBOutlet weak var tableView: UITableView!
  
    @IBOutlet weak var fireEvent: UIButton!
  
  let dataSource = ObservableArray([ObservableArray(["Archer", "Kirk", "Picard"]), ObservableArray(["T'Pol", "Spock", "Riker"])])
  
  var viewModel = ViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    self.viewModel.textFieldEditing.bindTo(self.textField.bnd_editing)
    self.viewModel.textViewEditing.bindTo(self.textView.bnd_editing)
    
    self.viewModel.someEvent.observeBecameTrue({
      print("fired if event became true")
    })
    
    self.viewModel.someEvent.observeTrue({
      print("fired if event is true")
    })
    
    self.viewModel.someEvent.observeFalse({
      print("fired if event is false")
    })
    
    self.viewModel.someEvent.observeBecameFalse({
      print("fired if event became false")
    })
    
    self.fireEvent.bnd_tap.observe { () -> () in
      self.viewModel.changeFireState()
    }
    
    let bgBtn = UIButton(type: UIButtonType.Custom)
    bgBtn.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))
    bgBtn.bnd_tap.observe { () -> () in
      self.textField.resignFirstResponder()
      self.textView.resignFirstResponder()
    }
    self.view.addSubview(bgBtn)
    self.view.bringSubviewToFront(self.textField)
    self.view.bringSubviewToFront(self.textView)
    self.view.bringSubviewToFront(self.fireEvent)
    
    self.dataSource.bindTo(self.tableView, proxyDataSource: nil, proxyDelegate: self) { (indexPath, dataSource, tableView) -> UITableViewCell in
      let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "title")
      cell.textLabel?.text = self.dataSource[indexPath.section][indexPath.row] as String
      return cell
    }

  }
  
  func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
     return 30
  }
  
//  func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//    return 30
//  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 100
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

