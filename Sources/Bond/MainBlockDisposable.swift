//
//  MainBlockDisposable.swift
//  
//
//  Created by Diego Rodriguez on 12/12/2019.
//

import Foundation
import ReactiveKit

/// A disposable that executes the given block on the main thread upon disposing.
public final class MainBlockDisposable: Disposable {
    private let _blockDisposable: BlockDisposable
    
    public init(_ handler: @escaping () -> ()) {
        _blockDisposable = BlockDisposable(handler)
    }
    
    public var isDisposed: Bool {
        return _blockDisposable.isDisposed
    }
    
    public func dispose() {
        ExecutionContext.immediateOnMain.execute { [weak self] in
          self?._blockDisposable.dispose()
        }
    }
}

