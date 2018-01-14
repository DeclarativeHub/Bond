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

public extension ReactiveExtensions where Base: NSButton {

    public var state: DynamicSubject<NSControl.StateValue> {
        return dynamicSubject(
            signal: controlEvent.eraseType(),
            get: { $0.state },
            set: { $0.state = $1 }
        )
    }

    public var title: Bond<String> {
        return bond { $0.title = $1 }
    }

    public var alternateTitle: Bond<String> {
        return bond { $0.alternateTitle = $1 }
    }

    public var image: Bond<NSImage?> {
        return bond { $0.image = $1 }
    }

    public var alternateImage: Bond<NSImage?> {
        return bond { $0.alternateImage = $1 }
    }

    public var imagePosition: Bond<NSControl.ImagePosition> {
        return bond { $0.imagePosition = $1 }
    }

    public var imageScaling: Bond<NSImageScaling> {
        return bond { $0.imageScaling = $1 }
    }

    @available(macOS 10.12, *)
    public var imageHugsTitle: Bond<Bool> {
        return bond { $0.imageHugsTitle = $1 }
    }

    public var isBordered: Bond<Bool> {
        return bond { $0.isBordered = $1 }
    }

    public var isTransparent: Bond<Bool> {
        return bond { $0.isTransparent = $1 }
    }

    public var keyEquivalent: Bond<String> {
        return bond { $0.keyEquivalent = $1 }
    }

    public var keyEquivalentModifierMask: Bond<NSEvent.ModifierFlags> {
        return bond { $0.keyEquivalentModifierMask = $1 }
    }

    @available(macOS 10.10.3, *)
    public var isSpringLoaded: Bond<Bool> {
        return bond { $0.isSpringLoaded = $1 }
    }

    @available(macOS 10.10.3, *)
    public var maxAcceleratorLevel: Bond<Int> {
        return bond { $0.maxAcceleratorLevel = $1 }
    }

    @available(macOS 10.12.2, *)
    public var bezelColor: Bond<NSColor?> {
        return bond { $0.bezelColor = $1 }
    }

    public var attributedTitle: Bond<NSAttributedString> {
        return bond { $0.attributedTitle = $1 }
    }

    public var attributedAlternateTitle: Bond<NSAttributedString> {
        return bond { $0.attributedAlternateTitle = $1 }
    }

    public var bezelStyle: Bond<NSButton.BezelStyle> {
        return bond { $0.bezelStyle = $1 }
    }

    public var allowsMixedState: Bond<Bool> {
        return bond { $0.allowsMixedState = $1 }
    }

    public var showsBorderOnlyWhileMouseInside: Bond<Bool> {
        return bond { $0.showsBorderOnlyWhileMouseInside = $1 }
    }

    public var sound: Bond<NSSound?> {
        return bond { $0.sound = $1 }
    }
}

#endif
