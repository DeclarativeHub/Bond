//
//  ViewController.swift
//  tvOSAppForTesting
//
//  Created by Matthew Buckley on 10/21/15.
//  Copyright © 2015 Bond. All rights reserved.
//

import UIKit
import Bond

class ViewController: UIViewController {

  @IBOutlet var mainView: UIView!
  let binary: Observable<Bool> = Observable(true)

  override func viewDidLoad() {
    super.viewDidLoad()

    let timer = NSTimer(timeInterval: 1.0, target: self, selector: "update", userInfo: nil, repeats: true)
    NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)

    // Bind the background color
    binary.observe({ value in
      self.mainView.backgroundColor = value ? .greenColor() : .yellowColor()
    })

  }

  func update() -> Void {
    binary.value = !binary.value
  }

}



