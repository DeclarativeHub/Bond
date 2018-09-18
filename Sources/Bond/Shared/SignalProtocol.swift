//
//  SignalProtocol.swift
//  Bond
//
//  Created by Srdan Rasic on 14/12/2016.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

#if os(iOS) || os(tvOS)

import ReactiveKit
import UIKit

extension SignalProtocol {

    /// Fires an event on start and every `interval` seconds as long as the app is in foreground.
    /// Pauses when the app goes to background. Restarts when the app is back in foreground.
    public static func heartbeat(interval seconds: Double) -> Signal<Void, NoError> {
        #if swift(>=4.2)
        let willEnterForegroundName = UIApplication.willEnterForegroundNotification
        let didEnterBackgorundName = UIApplication.didEnterBackgroundNotification
        #else
        let willEnterForegroundName = NSNotification.Name.UIApplicationDidEnterBackground
        let didEnterBackgorundName = NSNotification.Name.UIApplicationDidEnterBackground
        #endif
        
        let willEnterForeground = NotificationCenter.default.reactive.notification(name: willEnterForegroundName)
        let didEnterBackgorund = NotificationCenter.default.reactive.notification(name: didEnterBackgorundName)
        return willEnterForeground.replace(with: ()).start(with: ()).flatMapLatest { () -> Signal<Void, NoError> in
            return Signal<Int, NoError>.interval(seconds, queue: .global()).replace(with: ()).start(with: ()).take(until: didEnterBackgorund)
        }
    }
}
#endif
