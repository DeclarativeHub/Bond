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

public extension ReactiveExtensions where Base: NSSlider {

    public var minValue: Bond<Double> {
        return bond { $0.minValue = $1 }
    }

    public var maxValue: Bond<Double> {
        return bond { $0.maxValue = $1 }
    }

    public var altIncrementValue: Bond<Double> {
        return bond { $0.altIncrementValue = $1 }
    }

    @available(macOS 10.12, *)
    public var isVertical: Bond<Bool> {
        return bond { $0.isVertical = $1 }
    }

    @available(macOS 10.12.2, *)
    public var trackFillColor: Bond<NSColor?> {
        return bond { $0.trackFillColor = $1 }
    }

    public var numberOfTickMarks: Bond<Int> {
        return bond { $0.numberOfTickMarks = $1 }
    }

    public var tickMarkPosition: Bond<NSSlider.TickMarkPosition> {
        return bond { $0.tickMarkPosition = $1 }
    }

    public var allowsTickMarkValuesOnly: Bond<Bool> {
        return bond { $0.allowsTickMarkValuesOnly = $1 }
    }
}

extension NSSlider {

    public func bind(signal: Signal<Double, NoError>) -> Disposable {
        return reactive.doubleValue.bind(signal: signal)
    }
}

#endif
