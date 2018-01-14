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

public extension ReactiveExtensions where Base: NSProgressIndicator {

    public var isAnimating: Bond<Bool> {
        return bond {
            if $1 {
                $0.startAnimation(nil)
            } else {
                $0.stopAnimation(nil)
            }
        }
    }

    public var doubleValue: Bond<Double> {
        return bond { $0.doubleValue = $1 }
    }

    public var isIndeterminate: Bond<Bool> {
        return bond { $0.isIndeterminate = $1 }
    }

    public var minValue: Bond<Double> {
        return bond { $0.minValue = $1 }
    }

    public var maxValue: Bond<Double> {
        return bond { $0.maxValue = $1 }
    }

    public var controlTint: Bond<NSControlTint> {
        return bond { $0.controlTint = $1 }
    }

    public var controlSize: Bond<NSControl.ControlSize> {
        return bond { $0.controlSize = $1 }
    }

    public var style: Bond<NSProgressIndicator.Style> {
        return bond { $0.style = $1 }
    }

    public var isDisplayedWhenStopped: Bond<Bool> {
        return bond { $0.isDisplayedWhenStopped = $1 }
    }
}

extension NSProgressIndicator: BindableProtocol {

    public func bind(signal: Signal<Double, NoError>) -> Disposable {
        return reactive.doubleValue.bind(signal: signal)
    }
}

#endif
