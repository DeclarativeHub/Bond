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

public extension ReactiveExtensions where Base: NSSegmentedControl {

    public var segmentCount: Bond<Int> {
        return bond { $0.segmentCount = $1 }
    }

    public var selectedSegment: Bond<Int> {
        return bond { $0.selectedSegment = $1 }
    }

    public var segmentStyle: Bond<NSSegmentedControl.Style> {
        return bond { $0.segmentStyle = $1 }
    }

    @available(macOS 10.10.3, *)
    public var isSpringLoaded: Bond<Bool> {
        return bond { $0.isSpringLoaded = $1 }
    }

    @available(macOS 10.10.3, *)
    public var trackingMode: Bond<NSSegmentedControl.SwitchTracking> {
        return bond { $0.trackingMode = $1 }
    }

    @available(macOS 10.12.2, *)
    public var selectedSegmentBezelColor: Bond<NSColor?> {
        return bond { $0.selectedSegmentBezelColor = $1 }
    }
}

extension NSSegmentedControl {

    public func bind(signal: Signal<Int, NoError>) -> Disposable {
        return reactive.selectedSegment.bind(signal: signal)
    }
}

#endif
