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

class ViewController {
  let usernameTextField = UITextField()
  let passwordTextField = UITextField()
  let loginButton = UIButton()
  let viewModel: ViewModel
  
  var onLoginListener: Bond<UIControlEvents>?
  
  let didLoginEventListener = Bond<String?> {
    println("Logged in as \($0)")
  }
  
  init(viewModel: ViewModel) {
    self.viewModel = viewModel
  }

  func viewDidLoad() {
    viewModel.username <->> usernameTextField.textDynamic
    viewModel.password <->> passwordTextField.textDynamic
    viewModel.loginButtonEnabled ->> loginButton.enabledBond
    viewModel.loginSignal ->> didLoginEventListener
    
    onLoginListener = loginButton.eventDynamic.filter{ $0 == .TouchUpInside } ->> {
      [unowned self] event in
      self.viewModel.login()
    }
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
    // This is an example of a functional test case.
    XCTAssert(true, "Pass")
  }
  
}
