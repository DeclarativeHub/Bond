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

public extension ReactiveExtensions where Base: UIViewController {
    var lifecycleEvents: Signal<LifecycleEvent, Never> {
        self.base.lifecycleEvents.prefix(untilOutputFrom: base.deallocated)
    }

    func lifecycleEvent(_ event: LifecycleEvent) -> Signal<Void, Never> {
        self.lifecycleEvents.filter { $0 == event }.eraseType()
    }
}

public enum LifecycleEvent: CaseIterable {
    case viewDidLoad
    case viewWillAppear
    case viewDidAppear
    case viewWillDisappear
    case viewDidDisappear
    case viewWillLayoutSubviews
    case viewDidLayoutSubviews

    var associatedSelector: Selector {
        switch self {
        case .viewDidLoad:
            return #selector(UIViewController.viewDidLoad)
        case .viewWillAppear:
            return #selector(UIViewController.viewWillAppear(_:))
        case .viewDidAppear:
            return #selector(UIViewController.viewDidAppear(_:))
        case .viewWillDisappear:
            return #selector(UIViewController.viewWillDisappear(_:))
        case .viewDidDisappear:
            return #selector(UIViewController.viewDidDisappear(_:))
        case .viewWillLayoutSubviews:
            return #selector(UIViewController.viewWillLayoutSubviews)
        case .viewDidLayoutSubviews:
            return #selector(UIViewController.viewDidLayoutSubviews)
        }
    }
}

extension UIViewController {

    private enum StaticVariables {
        static var lifecycleSubjectKey = "lifecycleSubjectKey"
        static var swizzled = false
    }

    private var lifecycleEventsSubject: Subject<LifecycleEvent, Never> {
        if let subject = objc_getAssociatedObject(
            self,
            &StaticVariables.lifecycleSubjectKey
        ) as? Subject<LifecycleEvent, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<LifecycleEvent, Never>()
            objc_setAssociatedObject(
                self,
                &StaticVariables.lifecycleSubjectKey,
                subject,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            return subject
        }
    }

    private typealias _IMP_BOOL = @convention(c) (UnsafeRawPointer, Selector, Bool) -> Void
    private typealias _IMP = @convention(c) (UnsafeRawPointer, Selector) -> Void

    var lifecycleEvents: SafeSignal<LifecycleEvent> {
        let signal = isViewLoaded ? self.lifecycleEventsSubject.prepend(.viewDidLoad).toSignal() : self.lifecycleEventsSubject.toSignal()
        guard !StaticVariables.swizzled else { return signal }
        StaticVariables.swizzled = true
        for lifecycle in LifecycleEvent.allCases {
            let selector = lifecycle.associatedSelector
            guard let method = class_getInstanceMethod(UIViewController.self, selector) else { return signal }
            let existingImplementation = method_getImplementation(method)

            switch lifecycle {
            case .viewDidLoad,
                .viewDidLayoutSubviews,
                .viewWillLayoutSubviews:

                let newImplementation: @convention(block) (UnsafeRawPointer) -> Void = { me in
                    let viewController = unsafeBitCast(me, to: UIViewController.self)
                    viewController.lifecycleEventsSubject.send(lifecycle)
                    unsafeBitCast(existingImplementation, to: _IMP.self)(me, selector)
                }
                let swizzled = imp_implementationWithBlock(newImplementation)
                method_setImplementation(method, swizzled)

            case .viewWillAppear,
                .viewDidAppear,
                .viewWillDisappear,
                .viewDidDisappear:

                let newImplementation: @convention(block) (UnsafeRawPointer, Bool) -> Void = { me, animated in
                    let viewController = unsafeBitCast(me, to: UIViewController.self)
                    viewController.lifecycleEventsSubject.send(lifecycle)
                    unsafeBitCast(existingImplementation, to: _IMP_BOOL.self)(me, selector, animated)
                }
                let swizzled = imp_implementationWithBlock(newImplementation)
                method_setImplementation(method, swizzled)
            }
        }
        return signal
    }
}
#endif

