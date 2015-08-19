//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Tony Arnold (@tonyarnold)
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

import Cocoa


extension NSTextView {

  private struct AssociatedKeys {
    static var StringKey = "bnd_StringKey"
  }
  
  public var bnd_string: Observable<String> {
    if let bnd_string: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.StringKey) {
      return bnd_string as! Observable<String>
    } else {
      let bnd_string = Observable<String>(self.string ?? "")
      objc_setAssociatedObject(self, &AssociatedKeys.StringKey, bnd_string, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      var updatingFromSelf: Bool = false
      
      bnd_string.observeNew { (text: String) in // NSTextView cannot be referenced weakly
        if !updatingFromSelf {
          self.string = text
        }
      }
      
      NSNotificationCenter.defaultCenter().bnd_notification(NSTextViewDidChangeTypingAttributesNotification, object: self).observe { [weak bnd_string] notification in
        if let textView = notification.object as? NSTextView, bnd_string = bnd_string {
          updatingFromSelf = true
          bnd_string.next(textView.string ?? "")
          updatingFromSelf = false
        }
        }.disposeIn(bnd_bag)
      
      return bnd_string
    }
  }
}

