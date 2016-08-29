//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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
import ReactiveKit

extension UIBarButtonItem {

  public func bnd_tap() -> Signal1<Void> {
    let _self = self
    return Signal { [weak _self] observer in
      guard let _self = _self else {
        observer.completed()
        return NonDisposable.instance
      }
      let target = BNDBarButtonItemTarget(barButtonItem: _self) {
        observer.next()
      }
      return BlockDisposable {
        target.unregister()
      }
    }.take(until: bnd_deallocated)
  }
}

@objc fileprivate class BNDBarButtonItemTarget: NSObject
{
  private weak var barButtonItem: UIBarButtonItem?
  private let observer: () -> Void

  fileprivate init(barButtonItem: UIBarButtonItem, observer: @escaping () -> Void) {
    self.barButtonItem = barButtonItem
    self.observer = observer

    super.init()

    barButtonItem.target = self
    barButtonItem.action = #selector(BNDBarButtonItemTarget.actionHandler)
  }

  @objc private func actionHandler() {
    observer()
  }

  fileprivate func unregister() {
    barButtonItem?.target = nil
  }

  deinit {
    unregister()
  }
}
