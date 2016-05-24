//
//  ViewModel.swift
//  Bond
//
//  Created by ByteLee on 10/10/15.
//  Copyright © 2015 Bond. All rights reserved.
//

import Bond

class ViewModel {
  
  var textFieldEditing = Observable(false)
  var textViewEditing = Observable(false)
  var someEvent = Observable(false)
  
  
  init(){
    self.textFieldEditing.observeNew({editing in
      if editing{
        print("textfield begin editing")
      }else{
        print("textfield end editing")
      }
    })
    
    self.textViewEditing.observeNew({editing in
      if editing{
        print("text view  begin editing")
      }else{
        print("text view end editing")
      }
    })
  }
  
  func changeFireState(){
    if self.someEvent.value == true{
      self.someEvent.value = false
    }else{
      self.someEvent.value = true
    }
  }
}
