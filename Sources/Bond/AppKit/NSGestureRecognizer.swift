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

#if os(macOS)

import AppKit
import ReactiveKit

extension NSGestureRecognizer: BindingExecutionContextProvider {
    public var bindingExecutionContext: ExecutionContext { return .immediateOnMain }
}

public extension ReactiveExtensions where Base: NSGestureRecognizer {
    public var isEnabled: Bond<Bool> {
        return bond { $0.isEnabled = $1 }
    }
}

public extension ReactiveExtensions where Base: NSView {
    public func addGestureRecognizer<T: NSGestureRecognizer>(_ gestureRecognizer: T) -> SafeSignal<T> {
        let base = self.base
        return Signal { [weak base] observer in
            guard let base = base else {
                observer.completed()
                return NonDisposable.instance
            }
            let target = BNDGestureTarget(view: base, gestureRecognizer: gestureRecognizer) { recog in
                // swiftlint:disable:next force_cast
                observer.next(recog as! T)
            }
            return BlockDisposable {
                target.unregister()
            }
        }
        .take(until: base.deallocated)
    }

    public func clickGesture(numberOfClicks: Int = 1, numberOfTouches: Int = 1) -> SafeSignal<NSClickGestureRecognizer> {
        let gesture = NSClickGestureRecognizer()
        gesture.numberOfClicksRequired = numberOfClicks

        if #available(macOS 10.12.2, *) {
            gesture.numberOfTouchesRequired = numberOfTouches
        }

        return addGestureRecognizer(gesture)
    }

    public func magnificationGesture(magnification: CGFloat = 1.0, numberOfTouches: Int = 1) -> SafeSignal<NSMagnificationGestureRecognizer> {
        let gesture = NSMagnificationGestureRecognizer()
        gesture.magnification = magnification
        return addGestureRecognizer(gesture)
    }

    public func panGesture(buttonMask: Int = 0x01, numberOfTouches: Int = 1) -> SafeSignal<NSPanGestureRecognizer> {
        let gesture = NSPanGestureRecognizer()
        gesture.buttonMask = buttonMask

        if #available(macOS 10.12.2, *) {
            gesture.numberOfTouchesRequired = numberOfTouches
        }

        return addGestureRecognizer(gesture)
    }

    public func pressGesture(buttonMask: Int = 0x01, minimumPressDuration: TimeInterval = NSEvent.doubleClickInterval, allowableMovement: CGFloat = 10.0, numberOfTouches: Int = 1) -> SafeSignal<NSPressGestureRecognizer> {
        let gesture = NSPressGestureRecognizer()
        gesture.buttonMask = buttonMask
        gesture.minimumPressDuration = minimumPressDuration
        gesture.allowableMovement = allowableMovement

        if #available(macOS 10.12.2, *) {
            gesture.numberOfTouchesRequired = numberOfTouches
        }

        return addGestureRecognizer(gesture)
    }

    public func rotationGesture() -> SafeSignal<NSRotationGestureRecognizer> {
        return addGestureRecognizer(NSRotationGestureRecognizer())
    }
}

@objc private class BNDGestureTarget: NSObject {
    private weak var view: NSView?
    private let observer: (NSGestureRecognizer) -> Void
    private let gestureRecognizer: NSGestureRecognizer

    fileprivate init(view: NSView, gestureRecognizer: NSGestureRecognizer, observer: @escaping (NSGestureRecognizer) -> Void) {
        self.view = view
        self.gestureRecognizer = gestureRecognizer
        self.observer = observer

        super.init()

        gestureRecognizer.target = self
        gestureRecognizer.action = #selector(actionHandler(recogniser:))
        view.addGestureRecognizer(gestureRecognizer)
    }

    @objc private func actionHandler(recogniser: NSGestureRecognizer) {
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
