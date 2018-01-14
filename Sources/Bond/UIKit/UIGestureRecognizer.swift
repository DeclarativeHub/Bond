//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Sam Galizia (@sgalizia)
//  Copyright (c) 2017 Andy Bennett (@akbsteam)
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

#if os(iOS) || os(tvOS)

import UIKit
import ReactiveKit

extension UIGestureRecognizer: BindingExecutionContextProvider {
    public var bindingExecutionContext: ExecutionContext { return .immediateOnMain }
}

public extension ReactiveExtensions where Base: UIGestureRecognizer {

    public var isEnabled: Bond<Bool> {
        return bond { $0.isEnabled = $1 }
    }
}

#endif

#if os(iOS)

public extension ReactiveExtensions where Base: UIView {
    
    public func addGestureRecognizer<T: UIGestureRecognizer>(_ gestureRecognizer: T) -> SafeSignal<T> {
        let base = self.base
        return Signal { [weak base] observer in
            guard let base = base else {
                observer.completed()
                return NonDisposable.instance
            }
            let target = BNDGestureTarget(view: base, gestureRecognizer: gestureRecognizer) { recog in
                observer.next(recog as! T)
            }
            return BlockDisposable {
                target.unregister()
            }
            }.take(until: base.deallocated)
    }

    public func tapGesture(numberOfTaps: Int = 1, numberOfTouches: Int = 1) -> SafeSignal<UITapGestureRecognizer> {
        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = numberOfTaps
        gesture.numberOfTouchesRequired = numberOfTouches

        return addGestureRecognizer(gesture)
    }

    public func panGesture(numberOfTouches: Int = 1) -> SafeSignal<UIPanGestureRecognizer> {
        let gesture = UIPanGestureRecognizer()
        gesture.minimumNumberOfTouches = numberOfTouches

        return addGestureRecognizer(gesture)
    }

    public func swipeGesture(numberOfTouches: Int, direction: UISwipeGestureRecognizerDirection) -> SafeSignal<UISwipeGestureRecognizer> {
        let gesture = UISwipeGestureRecognizer()
        gesture.numberOfTouchesRequired = numberOfTouches
        gesture.direction = direction

        return addGestureRecognizer(gesture)
    }

    public func pinchGesture() -> SafeSignal<UIPinchGestureRecognizer> {
        return addGestureRecognizer(UIPinchGestureRecognizer())
    }

    public func longPressGesture(numberOfTaps: Int = 0, numberOfTouches: Int = 1,  minimumPressDuration: CFTimeInterval = 0.3, allowableMovement: CGFloat = 10) -> SafeSignal<UILongPressGestureRecognizer> {
        let gesture = UILongPressGestureRecognizer()
        gesture.numberOfTapsRequired = numberOfTaps
        gesture.numberOfTouchesRequired = numberOfTouches
        gesture.minimumPressDuration = minimumPressDuration
        gesture.allowableMovement = allowableMovement

        return addGestureRecognizer(gesture)
    }

    public func rotationGesture() -> SafeSignal<UIRotationGestureRecognizer> {
        return addGestureRecognizer(UIRotationGestureRecognizer())
    }
}

@objc fileprivate class BNDGestureTarget: NSObject {
    
    private weak var view: UIView?
    private let observer: (UIGestureRecognizer) -> Void
    private let gestureRecognizer: UIGestureRecognizer

    fileprivate init(view: UIView, gestureRecognizer: UIGestureRecognizer, observer: @escaping (UIGestureRecognizer) -> Void) {
        self.view = view
        self.gestureRecognizer = gestureRecognizer
        self.observer = observer

        super.init()

        gestureRecognizer.addTarget(self, action: #selector(actionHandler(recogniser:)))
        view.addGestureRecognizer(gestureRecognizer)
    }

    @objc private func actionHandler(recogniser: UIGestureRecognizer) {
        observer(recogniser)
    }

    fileprivate func unregister() {
        view?.removeGestureRecognizer(gestureRecognizer)
    }

    deinit {
        unregister()
    }
}

#endif
