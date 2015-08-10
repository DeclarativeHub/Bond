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

extension UILabel {
  
  private struct AssociatedKeys {
    static var TextKey = "bnd_TextKey"
    static var AttributedTextKey = "bnd_AttributedTextKey"
    static var TextColorKey = "bnd_TextColorKey"
  }
  
  public var bnd_text: Scalar<String?> {
    return bnd_associatedScalarForOptionalValueForKey("text", associationKey: &AssociatedKeys.TextKey)
  }
  
  public var bnd_attributedText: Scalar<NSAttributedString?> {
    return bnd_associatedScalarForOptionalValueForKey("attributedText", associationKey: &AssociatedKeys.AttributedTextKey)
  }
  
  public var bnd_textColor: Scalar<UIColor?> {
    return bnd_associatedScalarForOptionalValueForKey("textColor", associationKey: &AssociatedKeys.TextColorKey)
  }
}
