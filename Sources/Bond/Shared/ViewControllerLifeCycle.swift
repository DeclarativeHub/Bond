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
public final class ViewControllerLifeCycle {
  private let wrapperViewController: WrapperViewController
  public var viewDidLoad: SafeSignal<Void> {
    return self.wrapperViewController.viewDidLoadSubject.toSignal()
  }
  public var viewWillAppear: SafeSignal<Void> {
    return self.wrapperViewController.viewWillAppearSubject.toSignal()
  }
  public var viewDidAppear: SafeSignal<Void> {
    return self.wrapperViewController.viewDidAppearSubject.toSignal()
  }
  public var viewWillDisappear: SafeSignal<Void> {
    return self.wrapperViewController.viewWillDisappearSubject.toSignal()
  }
  public var viewDidDisappear: SafeSignal<Void> {
    return self.wrapperViewController.viewDidDisAppearSubject.toSignal()
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
        .observeNext { [weak viewController] _ in
          guard let viewController = viewController else { return }
          self.addAsChildViewController(viewController) // weak self ?
      }
        .dispose(in: viewController.bag)
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

private extension ViewControllerLifeCycle {
  final class WrapperViewController: UIViewController {
    fileprivate let viewDidLoadSubject       = SafeReplayOneSubject<Void>()
    fileprivate let viewWillAppearSubject    = SafeReplayOneSubject<Void>()
    fileprivate let viewDidAppearSubject     = SafeReplayOneSubject<Void>()
    fileprivate let viewWillDisappearSubject = SafeReplayOneSubject<Void>()
    fileprivate let viewDidDisAppearSubject  = SafeReplayOneSubject<Void>()
   
    override func viewDidLoad() {
      super.viewDidLoad()
      self.viewDidLoadSubject.send()
    }
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      self.viewWillAppearSubject.send()
    }
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      self.viewDidAppearSubject.send()
    }
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      self.viewWillDisappearSubject.send()
    }
    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      self.viewDidDisAppearSubject.send()
    }
  }
}

public protocol ViewControllerLibeCycleObservable: class {
  var rxLifeCycle: ViewControllerLifeCycle { get }
}

extension UIViewController: ViewControllerLibeCycleObservable {
  private struct AssociatedKeys {
    static var viewControllerLifeCycleKey = "viewControllerLifeCycleKey"
  }
  public var rxLifeCycle: ViewControllerLifeCycle {
    if let lifeCycle = objc_getAssociatedObject(self, &AssociatedKeys.viewControllerLifeCycleKey) {
      return lifeCycle as! ViewControllerLifeCycle
    } else {
      let lifeCycle = ViewControllerLifeCycle(viewController: self)
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.viewControllerLifeCycleKey,
        lifeCycle, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return lifeCycle
    }
  }
}

extension ReactiveExtensions where Base: ViewControllerLibeCycleObservable {
  var viewDidLoad: SafeSignal<Void> {
    return self.base.rxLifeCycle.viewDidLoad
  }
  var viewWillAppear: SafeSignal<Void> {
    return self.base.rxLifeCycle.viewWillAppear
  }
  var viewDidAppear: SafeSignal<Void> {
    return self.base.rxLifeCycle.viewDidAppear
  }
  var viewWillDisappear: SafeSignal<Void> {
    return self.base.rxLifeCycle.viewWillDisappear
  }
  var viewDidDisappear: SafeSignal<Void> {
    return self.base.rxLifeCycle.viewDidDisappear
  }
}
