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


import Foundation
import ReactiveKit

public protocol Deallocatable: class {
  var bnd_deallocated: Signal<Void, NoError> { get }
}

extension NSObject: Deallocatable {

  private struct AssociatedKeys {
    static var DeallocationSignalHelper = "DeallocationSignalHelper"
    static var DisposeBagKey = "r_DisposeBagKey"
  }

  private class BNDDeallocationSignalHelper {
    let subject = ReplayOneSubject<Void, NoError>()
    deinit {
      subject.completed()
    }
  }

  /// A signal that fires completion event when the object is deallocated.
  public var bnd_deallocated: Signal<Void, NoError> {
    if let helper = objc_getAssociatedObject(self, &AssociatedKeys.DeallocationSignalHelper) as? BNDDeallocationSignalHelper {
      return helper.subject.toSignal()
    } else {
      let helper = BNDDeallocationSignalHelper()
      objc_setAssociatedObject(self, &AssociatedKeys.DeallocationSignalHelper, helper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return helper.subject.toSignal()
    }
  }
  
  /// Use this bag to dispose disposables upon the deallocation of the receiver.
  public var bnd_bag: DisposeBag {
    if let disposeBag = objc_getAssociatedObject(self, &AssociatedKeys.DisposeBagKey) {
      return disposeBag as! DisposeBag
    } else {
      let disposeBag = DisposeBag()
      objc_setAssociatedObject(self, &AssociatedKeys.DisposeBagKey, disposeBag, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return disposeBag
    }
  }

  /// Bind `signal` to `bindable` and dispose in `bnd_bag` of receiver.
  @discardableResult
  public func bind<O: SignalProtocol, B: BindableProtocol>(_ signal: O, to bindable: B) where O.Element == B.Element, O.Error == NoError {
    signal.bind(to: bindable).disposeIn(bnd_bag)
  }
  
  /// Bind `signal` to `bindable` and dispose in `bnd_bag` of receiver.
  @discardableResult
  public func bind<O: SignalProtocol, B: BindableProtocol>(_ signal: O, to bindable: B) where B.Element: OptionalProtocol, O.Element == B.Element.Wrapped, O.Error == NoError {
    signal.bind(to: bindable).disposeIn(bnd_bag)
  }
}
