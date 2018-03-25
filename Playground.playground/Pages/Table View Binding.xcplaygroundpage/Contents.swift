//: Playground - noun: a place where people can play

import UIKit
import Bond
import ReactiveKit
import PlaygroundSupport
import CoreLocation

// Turn on the Assistant Editor to see the table view!

extension ReactiveExtensions where Base: CLLocationManager {

    public var delegate: ProtocolProxy {
        return protocolProxy(for: CLLocationManagerDelegate.self, keyPath: \.delegate)
    }

    public var locations: SafeSignal<[CLLocation]> {
        return delegate.signal(
            for: #selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)),
            dispatch: { (subject: SafePublishSubject<[CLLocation]>, locationManager: CLLocationManager, locations: [CLLocation]) in
                subject.next(locations)
            }
        )
    }
}

//: [Next](@next)

