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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    self.textField.bnd_editing.observeNew({editing in
      if editing{
        print("begin editing")
      }else{
        print("end editing")
      }
    })
    
    let bgBtn = UIButton(type: UIButtonType.Custom)
    bgBtn.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))
    bgBtn.bnd_tap.observe { () -> () in
      self.textField.resignFirstResponder()
    }
    self.view.addSubview(bgBtn)
    self.view.bringSubviewToFront(self.textField)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

