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

import ReactiveKit
import UIKit

public extension UIControl {

  public func bnd_controlEvents(_ events: UIControlEvents) -> Signal1<Void> {
    let _self = self
    return Signal { [weak _self] observer in
      guard let _self = _self else {
        observer.completed()
        return NonDisposable.instance
      }
      let target = BNDControlTarget(control: _self, events: events) {
        observer.next()
      }
      return BlockDisposable {
        target.unregister()
      }
    }.take(until: bnd_deallocated)
  }

  public var bnd_isEnabled: Bond<UIControl, Bool> {
    return Bond(target: self) { $0.isEnabled = $1 }
  }
}

@objc fileprivate class BNDControlTarget: NSObject
{
  private weak var control: UIControl?
  private let observer: () -> Void
  private let events: UIControlEvents

  fileprivate init(control: UIControl, events: UIControlEvents, observer: @escaping () -> Void) {
    self.control = control
    self.events = events
    self.observer = observer

    super.init()

    control.addTarget(self, action: #selector(actionHandler), for: events)
  }

  @objc private func actionHandler() {
    observer()
  }

  fileprivate func unregister() {
    control?.removeTarget(self, action: nil, for: events)
  }

  deinit {
    unregister()
  }
}
