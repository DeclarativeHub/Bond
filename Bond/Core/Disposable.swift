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

/// A disposable that does not do anything but encapsulating disposed state.
public final class SimpleDisposable: DisposableType {
  public private(set) var isDisposed: Bool = false
  
  public func dispose() {
    isDisposed = true
  }
}

/// A disposable that executes the given block upon disposing.
public final class BlockDisposable: DisposableType {
  
  public var isDisposed: Bool {
    return handler == nil
  }
  
  private var handler: (() -> ())?
  
  init(_ handler: () -> ()) {
    self.handler = handler
  }
  
  public func dispose() {
    handler?()
    handler = nil
  }
}

/// A disposable that disposes other disposable.
public final class SerialDisposable: DisposableType {
  public var isDisposed: Bool {
    return otherDisposable?.isDisposed ?? true
  }
  
  public var otherDisposable: DisposableType?
  
  init(otherDisposable: DisposableType?) {
    self.otherDisposable = otherDisposable
  }
  
  public func dispose() {
    otherDisposable?.dispose()
  }
}

/// A disposable that disposes a collection of disposables upon disposing.
public final class CompositeDisposable: DisposableType {
  public var isDisposed: Bool {
    return disposables == nil
  }
  
  private var disposables: [DisposableType]?
  
  convenience init() {
    self.init([])
  }
  
  init(_ disposables: [DisposableType]) {
    self.disposables = disposables
  }
  
  public func addDisposable(disposable: DisposableType) {
    disposables?.append(disposable)
  }
  
  public func dispose() {
    if let disposables = disposables {
      for disposable in disposables {
        disposable.dispose()
      }
    }
    
    disposables = nil
  }
}

public func += (left: CompositeDisposable, right: DisposableType) {
  left.addDisposable(right)
}

/// A disposable container that will dispose a collection of disposables upon deinit.
public final class DisposeBag: DisposableType {
  private var disposables: [DisposableType] = []
  
  /// This will return true whenever the bag is empty.
  public var isDisposed: Bool {
    return disposables.count == 0
  }
  
  /// Adds the given disposable to the bag.
  /// DisposableType will be disposed when the bag is deinitialized.
  public func addDisposable(disposable: DisposableType) {
    disposables.append(disposable)
  }
  
  /// Disposes all disposables that are currenty in the bag.
  public func dispose() {
    for disposable in disposables {
      disposable.dispose()
    }
    disposables = []
  }
  
  deinit {
    dispose()
  }
}

public extension DisposableType {
  public func disposeWith(disposeBag: DisposeBag) {
    disposeBag.addDisposable(self)
  }
}
