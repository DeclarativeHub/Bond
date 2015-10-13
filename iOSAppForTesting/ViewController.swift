//
//  ViewController.swift
//  iOSAppForTesting
//
//  Created by Anthony Egerton on 15/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import Bond

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
  
    @IBOutlet weak var textView: UITextView!
  
    @IBOutlet weak var fireEvent: UIButton!
  var viewModel = ViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    self.viewModel.textFieldEditing.bindTo(self.textField.bnd_editing)
    self.viewModel.textViewEditing.bindTo(self.textView.bnd_editing)
    
    self.viewModel.someEvent.observeNewTrue({
      print("new some event fire")
    })
    
    self.viewModel.someEvent.observeTrue({
      print("some event fire")
    })
    
    self.viewModel.someEvent.observeFalse({
      print("some event not fire")
    })
    
    self.viewModel.someEvent.observeNewFalse({5
      print("new some event not fire")
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
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

