//
//  SignalProtocol.swift
//  Bond
//
//  Created by Srdan Rasic on 14/12/2016.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import ReactiveKit

extension SignalProtocol {

  #if os(iOS) || os(tvOS)

  /// Fires an event on start and every `interval` seconds as long as the app is in foreground.
  /// Pauses when the app goes to background. Restarts when the app is back in foreground.
  public static func heartbeat(interval seconds: Double) -> Signal<Void, NoError> {
    let willEnterForeground = NotificationCenter.default.reactive.notification(name: .UIApplicationWillEnterForeground)
    let didEnterBackgorund = NotificationCenter.default.reactive.notification(name: .UIApplicationDidEnterBackground)
    return willEnterForeground.replace(with: ()).start(with: ()).flatMapLatest { () -> Signal<Void, NoError> in
      return Signal<Int, NoError>.interval(seconds, queue: .global()).replace(with: ()).start(with: ()).take(until: didEnterBackgorund)
    }
  }

  #endif
}
