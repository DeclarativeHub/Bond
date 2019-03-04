//
//  CBPeripheralManager.swift
//  Bond
//
//  Created by Pavlo Naumenko on 3/1/19.
//  Copyright © 2019 Swift Bond. All rights reserved.
//

import CoreBluetooth
import ReactiveKit
import Bond

#if os(iOS) || os(tvOS)

public extension ReactiveExtensions where Base: CBPeripheralManager {
    /// A `ProtocolProxy` for the peripheral manager delegate.
    ///
    /// - Note: Accessing this property for the first time will replace peripheral manager's current delegate
    /// with a protocol proxy object (an object that is stored in this property).
    /// Current delegate will be used as `forwardTo` delegate of protocol proxy.
    public var delegate: ProtocolProxy {
        return protocolProxy(for: CBPeripheralManagerDelegate.self, keyPath: \.delegate)
    }
    
    /// A signal that emits peripheral manager state.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManagerDidUpdateState(_:)` method.
    @available(iOS 10.0, *)
    public var didUpdateState: SafeSignal<CBManagerState> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManagerDidUpdateState(_:))) { (subject: SafePublishSubject<CBManagerState>, peripheral: CBPeripheralManager) in
            subject.next(peripheral.state)
        }
    }
    
    /// A signal that emits a dictionary containing information about peripheral that was preserved by the system at the time the app was terminated.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManager(_:willRestoreState:)` method.
    @available(iOS 6.0, *)
    public var willRestoreState: SafeSignal<[String : Any]> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManager(_:willRestoreState:))) { (subject: SafePublishSubject<[String : Any]>, peripheral: CBPeripheralManager, dict: [String : Any]) in
            subject.next(dict)
        }
    }
    
    /// A signal that emits error if any occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManagerDidStartAdvertising(_:error:)` method.
    @available(iOS 6.0, *)
    public var didStartAdvertising: SafeSignal<Error?> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManagerDidStartAdvertising(_:error:))) { (subject: SafePublishSubject<Error?>, peripheral: CBPeripheralManager, error: Error?) in
            subject.next(error)
        }
    }
    
    /// A signal that emits the service that was added to the local database if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManager(_:didAdd:error:)` method.
    @available(iOS 6.0, *)
    public var  didAddService: SafeSignal<(CBService, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManager(_:didAdd:error:))) { (subject: SafePublishSubject<(CBService, Error?)>, central: CBCentralManager, service: CBService, error: Error?) in
            subject.next((service, error))
        }
    }
    
    /// A signal that emits the central that issued the command and the characteristic on which notifications or indications were enabled.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManager(_:central:didSubscribeTo:)` method.
    @available(iOS 6.0, *)
    public var didSubscribeToCharacteristic: SafeSignal<(CBCentral, CBCharacteristic)> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManager(_:central:didSubscribeTo:))) { (subject: SafePublishSubject<(CBCentral, CBCharacteristic)>, peripheral: CBPeripheralManager, central: CBCentral,  characteristic: CBCharacteristic) in
            subject.next((central, characteristic))
        }
    }
    
    /// A signal that emits the central that issued the command and the characteristic on which notifications or indications were disabled.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManager(_:central:didSubscribeTo:)` method.
    @available(iOS 6.0, *)
    public var didUnsubscribeFromCharacteristic: SafeSignal<(CBCentral, CBCharacteristic)> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManager(_:central:didUnsubscribeFrom:))) { (subject: SafePublishSubject<(CBCentral, CBCharacteristic)>, peripheral: CBPeripheralManager, central: CBCentral,  characteristic: CBCharacteristic) in
            subject.next((central, characteristic))
        }
    }
    
    /// A signal that emits a CBATTRequest object.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManager(_:didReceiveRead:)` method.
    @available(iOS 6.0, *)
    public var didReceiveReadRequest: SafeSignal<CBATTRequest> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManager(_:didReceiveRead:))) { (subject: SafePublishSubject<CBATTRequest>, peripheral: CBPeripheralManager, request: CBATTRequest) in
            subject.next(request)
        }
    }
    
    /// A signal that emits a list of one or more CBATTRequest objects.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManager(_:didReceiveWrite:)` method.
    @available(iOS 6.0, *)
    public var didReceiveWriteRequests: SafeSignal<[CBATTRequest]> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManager(_:didReceiveWrite:))) { (subject: SafePublishSubject<[CBATTRequest]>, peripheral: CBPeripheralManager, requests: [CBATTRequest]) in
            subject.next(requests)
        }
    }
    
    /// A signal that emits Void after a failed call to updateValue:forCharacteristic:onSubscribedCentrals: when peripheral is again ready to send characteristic value updates.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManagerIsReady(toUpdateSubscribers:)` method.
    @available(iOS 6.0, *)
    public var IsReadyToUpdateSubscribers: SafeSignal<Void> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManagerIsReady(toUpdateSubscribers:))) { (subject: SafePublishSubject<Void>, peripheral: CBPeripheralManager) in
            subject.next()
        }
    }
    
    /// A signal that emits the PSM of the channel that was published. If an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManager(_:didPublishL2CAPChannel:error:)` method.
    @available(iOS 6.0, *)
    public var didPublishL2CAPChannel: SafeSignal<(CBL2CAPPSM, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManager(_:didPublishL2CAPChannel:error:))) { (subject: SafePublishSubject<(CBL2CAPPSM, Error?)>, peripheral: CBPeripheralManager, PSM: CBL2CAPPSM,  error: Error?) in
            subject.next((PSM, error))
        }
    }
    
    /// A signal that emits the PSM of the channel that was unpublished. If an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManager(_:didUnpublishL2CAPChannel:error:)` method.
    @available(iOS 6.0, *)
    public var didUnpublishL2CAPChannel: SafeSignal<(CBL2CAPPSM, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManager(_:didUnpublishL2CAPChannel:error:))) { (subject: SafePublishSubject<(CBL2CAPPSM, Error?)>, peripheral: CBPeripheralManager, PSM: CBL2CAPPSM,  error: Error?) in
            subject.next((PSM, error))
        }
    }
    
    /// A signal that emits CBL2CAPChannel when peripheral receives an ATT request or command for one or more characteristics with a dynamic value.
    ///
    /// - Note: Uses peripheral manager's `delegate` protocol proxy to observe calls made to `CBPeripheralManagerDelegate.peripheralManager(_:didOpen:error:)` method.
    @available(iOS 11.0, *)
    public var didOpenChannel: SafeSignal<(CBL2CAPChannel?, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralManagerDelegate.peripheralManager(_:didOpen:error:))) { (subject: SafePublishSubject<(CBL2CAPChannel?, Error?)>, peripheral: CBPeripheralManager, channel: CBL2CAPChannel?,  error: Error?) in
            subject.next((channel, error))
        }
    }
}

#endif
