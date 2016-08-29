//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
// /Users/srdan/Dropbox/Ideas/Bond/Sources/UIKit/UIActivityIndicatorView.swift:32:10: '(NSObject, Bool)' is not convertible to 'Bool' to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
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

import ReactiveKit
import UIKit

public extension UIActivityIndicatorView {

  public var bnd_animating: Bond<UIActivityIndicatorView, Bool> {
    return Bond(target: self) {
      if $1 {
        $0.startAnimating()
      } else {
        $0.stopAnimating()
      }
    }
  }
}

extension UIActivityIndicatorView: BindableProtocol {

  public func bind(signal: Signal<Bool, NoError>) -> Disposable {
    return bnd_animating.bind(signal: signal)
  }
}
