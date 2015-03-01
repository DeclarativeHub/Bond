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

enum LoginEvent {
  case LoggedIn(String)
  case Error(NSError)
  case None
}

class ViewModel {
  let username = Dynamic<String>("")
  let password = Dynamic<String>("")
  
  var loginButtonEnabled: Dynamic<Bool> {
    let usernameValid = username.map { countElements($0) > 2 }
    let passwordValid = username.map { countElements($0) > 2 }
    return reduce(usernameValid, passwordValid) { $0 && $1 }
  }
  
  let loginEventDynamic = Dynamic<LoginEvent>(.None)
  
  func login() {
    println("Logging in as \(username.value)")
    loginEventDynamic.value = .LoggedIn("Mike")
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
  
  let didLoginEventListener = Bond<(LoginEvent, ViewController)> { event, vc in
    switch event {
    case .LoggedIn(let username):
      println(username)
      vc.dismissViewControllerAnimated(false, completion: nil)
    case .Error(let error):
      print(error)
    default:
      break
    }
  }

  override func viewDidLoad() {
    viewModel.username <->> usernameTextField.dynText
    viewModel.password <->> passwordTextField.dynText
    
    viewModel.loginButtonEnabled ->> loginButton.dynEnabled
    viewModel.loginEventDynamic.zip(self) ->| didLoginEventListener
    
    loginButton.dynEvent.filter(==, .TouchUpInside).rewrite(self) ->> loginTapEventListener
  }
}
