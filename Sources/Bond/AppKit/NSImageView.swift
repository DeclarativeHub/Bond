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

public extension ReactiveExtensions where Base: NSImageView {

    public var image: Bond<NSImage?> {
        return bond { $0.image = $1 }
    }

    public var imageAlignment: Bond<NSImageAlignment> {
        return bond { $0.imageAlignment = $1 }
    }

    public var imageScaling: Bond<NSImageScaling> {
        return bond { $0.imageScaling = $1 }
    }

    public var imageFrameStyle: Bond<NSImageView.FrameStyle> {
        return bond { $0.imageFrameStyle = $1 }
    }

    public var isEditable: Bond<Bool> {
        return bond { $0.isEditable = $1 }
    }

    public var animates: Bond<Bool> {
        return bond { $0.animates = $1 }
    }

    public var allowsCutCopyPaste: Bond<Bool> {
        return bond { $0.allowsCutCopyPaste = $1 }
    }
}

extension NSImageView {

    public func bind(signal: Signal<NSImage?, NoError>) -> Disposable {
        return reactive.image.bind(signal: signal)
    }
}

#endif
