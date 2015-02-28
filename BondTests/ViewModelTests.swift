//
//  ViewModelTests.swift
//  Bond
//
//  Created by Srđan Rašić on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class ViewModel {
  let username = Dynamic<String>("")
  let password = Dynamic<String>("")
  
  var loginButtonEnabled: Dynamic<Bool> {
    let usernameValid = username.map { countElements($0) > 2 }
    let passwordValid = username.map { countElements($0) > 2 }
    return reduce(usernameValid, passwordValid) { $0 && $1 }
  }
  
  let loginSignal = Dynamic<String?>(nil)
  
  func login() {
    println("Logging in")
    loginSignal.value = "Mike"
  }
}

class ViewController: UIViewController {
  let usernameTextField = UITextField()
  let passwordTextField = UITextField()
  let loginButton = UIButton()
  let viewModel: ViewModel!
  
  let loginTapEventListener = Bond<ViewController> { vc in
    vc.viewModel.login()
  }
  
  let didLoginEventListener = Bond<(String?, ViewController)> { user, vc in
    println("Logged in as \(user)")
    vc.dismissViewControllerAnimated(false, completion: nil)
  }

  override func viewDidLoad() {
    viewModel.username <->> usernameTextField.textDynamic
    viewModel.password <->> passwordTextField.textDynamic
    
    viewModel.loginButtonEnabled ->> loginButton.enabledBond
    viewModel.loginSignal.rewrite(self) ->> didLoginEventListener
    
    loginButton.eventDynamic.filter(==, .TouchUpInside).rewrite(self) ->> loginTapEventListener
  }
}

class ViewModelTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testExample() {
    let button = UIButton()
    
    let bond = button.eventDynamic.filter { $0 == UIControlEvents.TouchUpInside } ->| { evnt in
      XCTFail("Should not be called")
    }
    
    
    XCTAssert(true, "Pass")
  }
  
}
