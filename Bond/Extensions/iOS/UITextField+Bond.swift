//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

extension UITextField {
  
  private struct AssociatedKeys {
    static var TextKey = "bnd_TextKey"
    static var AttributedTextKey = "bnd_AttributedTextKey"
  }
  
  public var bnd_text: Observable<String?> {
    if let bnd_text: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.TextKey) {
      return bnd_text as! Observable<String?>
    } else {
      let bnd_text = Observable<String?>(self.text)
      objc_setAssociatedObject(self, &AssociatedKeys.TextKey, bnd_text, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      var updatingFromSelf: Bool = false
      
      bnd_text.observeNew { [weak self] (text: String?) in
        if !updatingFromSelf {
          self?.text = text
        }
      }
      
      self.bnd_controlEvent.filter { $0 == UIControlEvents.EditingChanged }.observe { [weak self, weak bnd_text] event in
        guard let unwrappedSelf = self, let bnd_text = bnd_text else { return }
        updatingFromSelf = true
        bnd_text.next(unwrappedSelf.text)
        updatingFromSelf = false
      }
      
      return bnd_text
    }
  }
  
  public var bnd_attributedText: Observable<NSAttributedString?> {
    if let bnd_attributedText: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.AttributedTextKey) {
      return bnd_attributedText as! Observable<NSAttributedString?>
    } else {
      let bnd_attributedText = Observable<NSAttributedString?>(self.attributedText)
      objc_setAssociatedObject(self, &AssociatedKeys.AttributedTextKey, bnd_attributedText, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      var updatingFromSelf: Bool = false
      
      bnd_attributedText.observeNew { [weak self] (text: NSAttributedString?) in
        if !updatingFromSelf {
          self?.attributedText = text
        }
      }
      
      self.bnd_controlEvent.filter { $0 == UIControlEvents.EditingChanged }.observe { [weak self, weak bnd_attributedText] event in
        guard let unwrappedSelf = self, let bnd_attributedText = bnd_attributedText else { return }
        updatingFromSelf = true
        bnd_attributedText.next(unwrappedSelf.attributedText)
        updatingFromSelf = false
      }
      
      return bnd_attributedText
    }
  }
  
  public var bnd_textColor: Observable<UIColor?> {
    return bnd_associatedObservableForValueForKey("textColor")
  }
}

