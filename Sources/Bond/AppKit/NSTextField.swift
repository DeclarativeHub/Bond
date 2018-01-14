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

public extension ReactiveExtensions where Base: NSTextField {

    public var font: Bond<NSFont?> {
        return bond { $0.font = $1 }
    }

    public var textColor: Bond<NSColor?> {
        return bond { $0.textColor = $1 }
    }

    public var backgroundColor: Bond<NSColor?> {
        return bond { $0.backgroundColor = $1 }
    }

    public var placeholderString: Bond<String?> {
        return bond { $0.placeholderString = $1 }
    }

    public var placeholderAttributedString: Bond<NSAttributedString?> {
        return bond { $0.placeholderAttributedString = $1 }
    }

    public var editingString: DynamicSubject<String> {
        return dynamicSubject(
            signal: self.textDidChange.eraseType(),
            get: { (textField: NSTextField) -> String in
                return textField.formatter?.editingString(for: textField.stringValue) ?? textField.stringValue
            },
            set: { (textField: NSTextField, value: String) in
                textField.stringValue = value
            }
        )
    }

    public var textDidChange: SafeSignal<NSTextField> {
        return NotificationCenter.default
            .reactive.notification(name: NSControl.textDidChangeNotification, object: base)
            .map { $0.object as? NSTextField }
            .ignoreNil()
    }

    public var textDidBeginEditing: SafeSignal<NSTextField> {
        return NotificationCenter.default
            .reactive.notification(name: NSControl.textDidBeginEditingNotification, object: base)
            .map { $0.object as? NSTextField }
            .ignoreNil()
    }

    public var textDidEndEditing: SafeSignal<(NSTextField, Bool)> {
        return NotificationCenter.default
            .reactive.notification(name: NSControl.textDidEndEditingNotification, object: base)
            .map { notification -> (NSTextField, Bool)? in
                guard let textField = notification.object as? NSTextField else {
                    return nil
                }

                return (textField, Self.resignedFirstResponder(in: notification))
            }
            .ignoreNil()
    }

    /// Interrogates the passed notification for details of how the field ended editing, and if it resigned its first responder status as a result.
    ///
    /// - Parameter notification: Notification of type `NSControlTextDidEndEditing`
    /// - Returns: true if the text field resigned first responder, false if it did not
    private static func resignedFirstResponder(in notification: Notification) -> Bool {
        guard
            notification.name == NSControl.textDidEndEditingNotification,
            let textField = notification.object as? NSTextField,
            let textMovement = notification.userInfo?["NSTextMovement"] as? Int
            else {
                return false
            }

        let returnKeyPressed = (textMovement == NSReturnTextMovement)
        let tabKeyPressed = (textMovement == NSTabTextMovement || textMovement == NSBacktabTextMovement)
        let tabbedIntoTextField = tabKeyPressed && textField.nextKeyView == textField
        let tabbedOutOfTextField = tabKeyPressed && textField.nextKeyView == nil

        return (returnKeyPressed || tabbedIntoTextField || tabbedOutOfTextField)
    }
}

extension NSTextField {

    public func bind(signal: Signal<String, NoError>) -> Disposable {
        return reactive.stringValue.bind(signal: signal)
    }
}

#endif
