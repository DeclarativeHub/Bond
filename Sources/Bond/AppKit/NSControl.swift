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

fileprivate extension NSControl {

    struct AssociatedKeys {
        static var ControlHelperKey = "bnd_ControlHelperKey"
    }

    @objc class BondHelper: NSObject
    {
        weak var control: NSControl?
        let subject = PublishSubject<AnyObject?, NoError>()

        init(control: NSControl) {
            self.control = control
            super.init()

            control.target = self
            control.action = #selector(eventHandler)
        }

        @objc func eventHandler(_ sender: NSControl?) {
            subject.next(sender)
        }

        deinit {
            control?.target = nil
            control?.action = nil
            subject.completed()
        }
    }
}

public extension ReactiveExtensions where Base: NSControl {

    public var controlEvent: SafeSignal<Base> {
        if let controlHelper = objc_getAssociatedObject(base, &NSControl.AssociatedKeys.ControlHelperKey) as AnyObject? {
            return (controlHelper as! NSControl.BondHelper).subject.map { $0 as! Base }.toSignal()
        } else {
            let controlHelper = NSControl.BondHelper(control: base)
            objc_setAssociatedObject(base, &NSControl.AssociatedKeys.ControlHelperKey, controlHelper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return controlHelper.subject.map { $0 as! Base }.toSignal()
        }
    }

    public func controlEvent<T>(_ read: @escaping (Base) -> T) -> SafeSignal<T> {
        return controlEvent.map(read)
    }

    public var isEnabled: DynamicSubject<Bool> {
        return dynamicSubject(
            signal: keyPath(#keyPath(NSControl.isEnabled), ofType: Bool.self).eraseType(),
            triggerEventOnSetting: false,
            get: { $0.isEnabled },
            set: { $0.isEnabled = $1 }
        )
    }

    public var isHighlighted: DynamicSubject<Bool> {
        return dynamicSubject(
            signal: keyPath(#keyPath(NSControl.isHighlighted), ofType: Bool.self).eraseType(),
            triggerEventOnSetting: false,
            get: { $0.isHighlighted },
            set: { $0.isHighlighted = $1 }
        )
    }

    public var objectValue: DynamicSubject<Any?> {
        return dynamicSubject(
            signal: keyPath(#keyPath(NSControl.objectValue), ofType: Optional<Any>.self).eraseType(),
            triggerEventOnSetting: false,
            get: { $0.objectValue },
            set: { $0.objectValue = $1 }
        )
    }

    public var stringValue: DynamicSubject<String> {
        return dynamicSubject(
            signal: keyPath(#keyPath(NSControl.stringValue), ofType: String.self).eraseType(),
            triggerEventOnSetting: false,
            get: { $0.stringValue },
            set: { $0.stringValue = $1 }
        )
    }

    public var attributedStringValue: DynamicSubject<NSAttributedString> {
        return dynamicSubject(
            signal: keyPath(#keyPath(NSControl.attributedStringValue), ofType: NSAttributedString.self).eraseType(),
            triggerEventOnSetting: false,
            get: { $0.attributedStringValue },
            set: { $0.attributedStringValue = $1 }
        )
    }

    public var integerValue: DynamicSubject<Int> {
        return dynamicSubject(
            signal: keyPath(#keyPath(NSControl.integerValue), ofType: Int.self).eraseType(),
            triggerEventOnSetting: false,
            get: { $0.integerValue },
            set: { $0.integerValue = $1 }
        )
    }

    public var floatValue: DynamicSubject<Float> {
        return dynamicSubject(
            signal: keyPath(#keyPath(NSControl.floatValue), ofType: Float.self).eraseType(),
            triggerEventOnSetting: false,
            get: { $0.floatValue },
            set: { $0.floatValue = $1 }
        )
    }

    public var doubleValue: DynamicSubject<Double> {
        return dynamicSubject(
            signal: keyPath(#keyPath(NSControl.doubleValue), ofType: Double.self).eraseType(),
            triggerEventOnSetting: false,
            get: { $0.doubleValue },
            set: { $0.doubleValue = $1 }
        )
    }

    @available(*, deprecated, message: "Use attributedStringValue instead.")
    public var attributedStringleValue: DynamicSubject<NSAttributedString> {
        return attributedStringValue
    }
}

extension NSControl: BindableProtocol {

    public func bind(signal: Signal<Any?, NoError>) -> Disposable {
        return reactive.objectValue.bind(signal: signal)
    }
}

#endif
