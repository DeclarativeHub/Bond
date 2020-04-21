//
//  ViewControllerLifeCycle.swift
//  Bond-iOS
//
//  Created by Ibrahim Koteish on 21/03/2020.
//  Copyright © 2020 Swift Bond. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Foundation
import UIKit
import ReactiveKit

public enum LifecycleEvent {
    case viewDidLoad
    case viewWillAppear
    case viewDidAppear
    case viewWillDisappear
    case viewDidDisappear
    case viewDidLayoutSubviews
    case viewWillLayoutSubviews
}

/// Observe UIViewController life cycle events
public final class ViewControllerLifecycle {
    
    private let wrapperViewController: WrapperViewController
    
    public var lifecycleEvents: Signal<LifecycleEvent, Never> {
        self.wrapperViewController.lifecycleEvents
    }
    
    public func lifecycleEvent(_ event: LifecycleEvent) -> Signal<Void, Never> {
        self.wrapperViewController.lifecycleEvent(event)
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
                    self.addAsChildViewController(viewController)
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
    public var lifecycleEvents: Signal<LifecycleEvent, Never> {
        self.base.viewControllerLifecycle.lifecycleEvents
    }

    public func lifecycleEvent(_ event: LifecycleEvent) -> Signal<Void, Never> {
        self.base.viewControllerLifecycle.lifecycleEvent(event)
    }
}

#endif
