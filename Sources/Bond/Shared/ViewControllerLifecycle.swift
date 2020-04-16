//
//  ViewControllerLifeCycle.swift
//  Bond-iOS
//
//  Created by Ibrahim Koteish on 21/03/2020.
//  Copyright © 2020 Swift Bond. All rights reserved.
//

import Foundation
import UIKit
import ReactiveKit

/// Observe UIViewController life cycle events
public final class ViewControllerLifecycle {
    
    private let wrapperViewController: WrapperViewController
    
    public var viewDidLoad: SafeSignal<Void> {
        return self.wrapperViewController.lifecycleEvent(.viewDidLoad)
    }
    
    public var viewWillAppear: SafeSignal<Void> {
        return self.wrapperViewController.lifecycleEvent(.viewWillAppear)
    }
    
    public var viewDidAppear: SafeSignal<Void> {
        return self.wrapperViewController.lifecycleEvent(.viewDidAppear)
    }
    
    public var viewWillDisappear: SafeSignal<Void> {
        return self.wrapperViewController.lifecycleEvent(.viewWillDisappear)
    }
    
    public var viewDidDisappear: SafeSignal<Void> {
        return self.wrapperViewController.lifecycleEvent(.viewDidDisappear)
    }
    
    public var viewWillLayoutSubviews: SafeSignal<Void> {
        return self.wrapperViewController.lifecycleEvent(.viewWillLayoutSubviews)
    }
    
    public var viewDidLayoutSubviews: SafeSignal<Void> {
        return self.wrapperViewController.lifecycleEvent(.viewDidLayoutSubviews)
    }
    
    public init(viewController: UIViewController) {
        self.wrapperViewController = WrapperViewController()
        if viewController.isViewLoaded {
            self.addAsChildViewController(viewController)
        } else {
            viewController
                .reactive
                .keyPath(\.view, startWithCurrentValue: false)
                .prefix(maxLength: 1)
                .bind(to: viewController) { (viewController, _) in
                    self.addAsChildViewController(viewController) // weak self ?
            }
        }
    }
    
    private func addAsChildViewController(_ viewController: UIViewController) {
        
        viewController.addChild(self.wrapperViewController)
        viewController.view.addSubview(self.wrapperViewController.view)
        self.wrapperViewController.view.frame = .zero
        self.wrapperViewController.view.autoresizingMask = []
        self.wrapperViewController.didMove(toParent: viewController)
    }
}

private extension ViewControllerLifecycle {
    
    final class WrapperViewController: UIViewController {
        
        public enum LifecycleEvent {
            case viewDidLoad
            case viewWillAppear
            case viewDidAppear
            case viewWillDisappear
            case viewDidDisappear
            case viewDidLayoutSubviews
            case viewWillLayoutSubviews
        }
        
        deinit {
            _lifecycleEvent.send(completion: .finished)
        }
        
        private let _lifecycleEvent = PassthroughSubject<LifecycleEvent, Never>()
        
        public var lifecycleEvents: Signal<LifecycleEvent, Never> {
            var signal = _lifecycleEvent.toSignal()
            if isViewLoaded {
                signal = signal.prepend(.viewDidLoad)
            }
            return signal
        }
        
        public func lifecycleEvent(_ event: LifecycleEvent) -> Signal<Void, Never> {
            return lifecycleEvents.filter { $0 == event }.eraseType()
        }
        
        //MARK: - Overrides
        override func viewDidLoad() {
            super.viewDidLoad()
            _lifecycleEvent.send(.viewDidLoad)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            _lifecycleEvent.send(.viewWillAppear)
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            _lifecycleEvent.send(.viewDidAppear)
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            _lifecycleEvent.send(.viewWillDisappear)
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            _lifecycleEvent.send(.viewDidDisappear)
        }
        
        override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()
            _lifecycleEvent.send(.viewWillLayoutSubviews)
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            _lifecycleEvent.send(.viewDidLayoutSubviews)
        }
    }
}

public protocol ViewControllerLifecycleProvider: class {
    var viewControllerLifecycle: ViewControllerLifecycle { get }
}

extension UIViewController: ViewControllerLifecycleProvider {
    
    private struct AssociatedKeys {
        static var viewControllerLifeCycleKey = "viewControllerLifeCycleKey"
    }
    
    public var viewControllerLifecycle: ViewControllerLifecycle {
        if let lifeCycle = objc_getAssociatedObject(self, &AssociatedKeys.viewControllerLifeCycleKey) {
            return lifeCycle as! ViewControllerLifecycle
        } else {
            let lifeCycle = ViewControllerLifecycle(viewController: self)
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.viewControllerLifeCycleKey,
                lifeCycle, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return lifeCycle
        }
    }
}

extension ReactiveExtensions where Base: ViewControllerLifecycleProvider {
    
    var viewDidLoad: SafeSignal<Void> {
        return self.base.viewControllerLifecycle.viewDidLoad
    }
    
    var viewWillAppear: SafeSignal<Void> {
        return self.base.viewControllerLifecycle.viewWillAppear
    }
    
    var viewDidAppear: SafeSignal<Void> {
        return self.base.viewControllerLifecycle.viewDidAppear
    }
    
    var viewWillDisappear: SafeSignal<Void> {
        return self.base.viewControllerLifecycle.viewWillDisappear
    }
    
    var viewDidDisappear: SafeSignal<Void> {
        return self.base.viewControllerLifecycle.viewDidDisappear
    }
    
    var viewWillLayoutSubviews: SafeSignal<Void> {
        return self.base.viewControllerLifecycle.viewWillLayoutSubviews
    }
    
    var viewDidLayoutSubviews: SafeSignal<Void> {
        return self.base.viewControllerLifecycle.viewDidLayoutSubviews
    }
}
