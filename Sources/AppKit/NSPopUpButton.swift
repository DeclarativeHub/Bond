//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Tony Arnold (@tonyarnold)
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

import AppKit
import ReactiveKit

public extension ReactiveExtensions where Base: NSPopUpButton {

  public var selectedItem: DynamicSubject<NSMenuItem?> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSPopUpButton.selectedItem), ofType: Optional<NSMenuItem>.self).eraseType(),
      get: { $0.selectedItem },
      set: { $0.select($1) }
    )
  }

  public var selectedItemAtIndex: DynamicSubject<Int?> {
    return dynamicSubject(
      signal: selectedItem.toSignal().eraseType(),
      get: { $0.indexOfSelectedItem >= 0 ? $0.indexOfSelectedItem : nil },
      set: { $0.selectItem(at: $1 ?? -1) }
    )
  }

  public var selectedItemWithTitle: DynamicSubject<String?> {
    return dynamicSubject(
      signal: selectedItem.toSignal().eraseType(),
      get: { $0.titleOfSelectedItem },
      set: { $0.selectItem(withTitle: $1 ?? "") }
    )
  }

  public var selectedItemWithTag: DynamicSubject<Int> {
    return dynamicSubject(
      signal: selectedItem.toSignal().eraseType(),
      get: { $0.selectedItem?.tag ?? -1 },
      set: { $0.selectItem(withTag: $1) }
    )
  }
}

extension NSPopUpButton: BindableProtocol {

  public func bind(signal: Signal<NSMenuItem?, NoError>) -> Disposable {
    return reactive.selectedItem.bind(signal: signal)
  }
}
