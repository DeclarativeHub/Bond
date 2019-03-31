//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 DeclarativeHub/Bond
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

extension SignalProtocol {

    /// Fires an event on start and every `interval` seconds as long as the app is in foreground.
    /// Pauses when the app goes to background. Restarts when the app is back in foreground.
    public static func heartbeat(interval seconds: Double) -> Signal<Void, Never> {
        let willEnterForeground = NotificationCenter.default.reactive.notification(name: UIApplication.willEnterForegroundNotification)
        let didEnterBackgorund = NotificationCenter.default.reactive.notification(name: UIApplication.didEnterBackgroundNotification)
        return willEnterForeground.replaceElements(with: ()).start(with: ()).flatMapLatest { () -> Signal<Void, Never> in
            return SafeSignal<Int>(sequence: 0..., interval: seconds, queue: .global()).replaceElements(with: ()).start(with: ()).take(until: didEnterBackgorund)
        }
    }
}
#endif
