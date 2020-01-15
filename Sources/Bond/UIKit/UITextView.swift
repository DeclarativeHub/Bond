//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

    import ReactiveKit
    import UIKit

    extension ReactiveExtensions where Base: UITextView {
        public var text: DynamicSubject<String?> {
            let notificationName = UITextView.textDidChangeNotification
            return dynamicSubject(
                signal: NotificationCenter.default.reactive.notification(name: notificationName, object: base).eraseType(),
                get: { $0.text },
                set: { $0.text = $1 }
            )
        }

        public var attributedText: DynamicSubject<NSAttributedString?> {
            let notificationName = UITextView.textDidChangeNotification
            return dynamicSubject(
                signal: NotificationCenter.default.reactive.notification(name: notificationName, object: base).eraseType(),
                get: { $0.attributedText },
                set: { $0.attributedText = $1 }
            )
        }

        public var textColor: Bond<UIColor?> {
            return bond { $0.textColor = $1 }
        }
    }

    extension UITextView: BindableProtocol {
        public func bind(signal: Signal<String?, Never>) -> Disposable {
            return reactive.text.bind(signal: signal)
        }
    }

#endif
