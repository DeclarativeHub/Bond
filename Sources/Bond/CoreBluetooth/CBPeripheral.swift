//
//  CBPeripheral.swift
//  Bond
//
//  Created by Pavlo Naumenko on 3/1/19.
//  Copyright © 2019 Swift Bond. All rights reserved.
//

import CoreBluetooth
import ReactiveKit

#if os(iOS) || os(tvOS)

public extension ReactiveExtensions where Base: CBPeripheral {
    
    /// A `ProtocolProxy` for the peripheral delegate.
    ///
    /// - Note: Accessing this property for the first time will replace peripheral's current delegate
    /// with a protocol proxy object (an object that is stored in this property).
    /// Current delegate will be used as `forwardTo` delegate of protocol proxy.
    public var delegate: ProtocolProxy {
        return protocolProxy(for: CBPeripheralDelegate.self, keyPath: \.delegate)
    }
    
    /// A signal that emits peripheral's name update.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheralDidUpdateName(_:)` method.
    @available(iOS 6.0, *)
    public var didUpdateName: SafeSignal<String?> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheralDidUpdateName(_:))) { (subject: SafePublishSubject<String?>, peripheral: CBPeripheral) in
            subject.next(peripheral.name)
        }
    }
    
    /// A signal that emits the peripheral providing this update and The services that have been invalidated.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didModifyServices:)` method.
    @available(iOS 7.0, *)
    public var didModifyServices: SafeSignal<[CBService]> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didModifyServices:))) { (subject: SafePublishSubject<[CBService]>, peripheral: CBPeripheral, invalidatedServices: [CBService]) in
            subject.next(invalidatedServices)
        }
    }
    
    /// A signal that emits the current RSSI of the link and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didReadRSSI:error:)` method.
    @available(iOS 8.0, *)
    public var didReadRSSI: SafeSignal<(NSNumber, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didReadRSSI:error:))) { (subject: SafePublishSubject<(NSNumber, Error?)>, peripheral: CBPeripheral, RSSI: NSNumber, error: Error?) in
            subject.next((RSSI, error))
        }
    }
    
    /// A signal that emits peripheral's discovered services and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didDiscoverServices:)` method.
    @available(iOS 5.0, *)
    public var didDiscoverServices: SafeSignal<([CBService]?, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didDiscoverServices:))) { (subject: SafePublishSubject<([CBService]?, Error?)>, peripheral: CBPeripheral, error: Error?) in
            subject.next((peripheral.services, error))
        }
    }
    
    /// A signal that emits CBService object containing the included services and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didDiscoverIncludedServicesFor:error:)` method.
    @available(iOS 5.0, *)
    public var didDiscoverIncludedServicesForService: SafeSignal<(CBService, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didDiscoverIncludedServicesFor:error:))) { (subject: SafePublishSubject<(CBService, Error?)>, peripheral: CBPeripheral, service: CBService, error: Error?) in
            subject.next((service, error))
        }
    }
    
    /// A signal that emits CBService object containing the characteristic(s) and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didDiscoverCharacteristicsFor:error:)` method.
    @available(iOS 5.0, *)
    public var didDiscoverCharacteristicsForService: SafeSignal<(CBService, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didDiscoverCharacteristicsFor:error:))) { (subject: SafePublishSubject<(CBService, Error?)>, peripheral: CBPeripheral, service: CBService, error: Error?) in
            subject.next((service, error))
        }
    }
    
    /// A signal that emits CBCharacteristic object and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didUpdateValueFor:error:)` method.
    @available(iOS 5.0, *)
    public var didUpdateValueForCharacteristic: SafeSignal<(CBCharacteristic, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didUpdateValueFor:error:) as ((CBPeripheralDelegate) -> (CBPeripheral, CBCharacteristic, Error?) -> Void)?)) { (subject: SafePublishSubject<(CBCharacteristic, Error?)>, peripheral: CBPeripheral, characteristic: CBCharacteristic, error: Error?) in
            subject.next((characteristic, error))
        }
    }
    
    /// A signal that emits CBCharacteristic object and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didWriteValueFor:error:)` method.
    @available(iOS 5.0, *)
    public var didWriteValueForCharacteristic: SafeSignal<(CBCharacteristic, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didWriteValueFor:error:) as ((CBPeripheralDelegate) -> (CBPeripheral, CBCharacteristic, Error?) -> Void)?)) { (subject: SafePublishSubject<(CBCharacteristic, Error?)>, peripheral: CBPeripheral, characteristic: CBCharacteristic, error: Error?) in
            subject.next((characteristic, error))
        }
    }
    
    /// A signal that emits CBCharacteristic object and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didUpdateNotificationStateFor:error:)` method.
    @available(iOS 5.0, *)
    public var didUpdateNotificationStateForCharacteristics: SafeSignal<(CBCharacteristic, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didUpdateNotificationStateFor:error:))) { (subject: SafePublishSubject<(CBCharacteristic, Error?)>, peripheral: CBPeripheral, characteristic: CBCharacteristic, error: Error?) in
            subject.next((characteristic, error))
        }
    }
    
    /// A signal that emits CBCharacteristic object and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didDiscoverDescriptorsFor:error:)` method.
    @available(iOS 5.0, *)
    public var didDiscoverDescriptorsForCharacteristics: SafeSignal<(CBCharacteristic, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didDiscoverDescriptorsFor:error:))) { (subject: SafePublishSubject<(CBCharacteristic, Error?)>, peripheral: CBPeripheral, characteristic: CBCharacteristic, error: Error?) in
            subject.next((characteristic, error))
        }
    }
    
    /// A signal that emits CBDescriptor object and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didUpdateValueFor:error:)` method.
    @available(iOS 5.0, *)
    public var didUpdateValueForDescriptor: SafeSignal<(CBDescriptor, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didUpdateValueFor:error:) as ((CBPeripheralDelegate) -> (CBPeripheral, CBDescriptor, Error?) -> Void)?)) { (subject: SafePublishSubject<(CBDescriptor, Error?)>, peripheral: CBPeripheral, descriptor: CBDescriptor, error: Error?) in
            subject.next((descriptor, error))
        }
    }
    
    /// A signal that emits CBDescriptor object and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didWriteValueFor:error:)` method.
    @available(iOS 5.0, *)
    public var didWriteValueForDescriptor: SafeSignal<(CBDescriptor, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didWriteValueFor:error:) as ((CBPeripheralDelegate) -> (CBPeripheral, CBDescriptor, Error?) -> Void)?)) { (subject: SafePublishSubject<(CBDescriptor, Error?)>, peripheral: CBPeripheral, descriptor: CBDescriptor, error: Error?) in
            subject.next((descriptor, error))
        }
    }
    
    /// A signal that emits void to notify when peripheral is again ready to send characteristic value updates.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheralIsReady(toSendWriteWithoutResponse:)` method.
    @available(iOS 5.0, *)
    public var isReadyToSendWriteWithoutResponse: SafeSignal<Void> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheralIsReady(toSendWriteWithoutResponse:))) { (subject: SafePublishSubject<Void>, peripheral: CBPeripheral) in
            subject.next()
        }
    }
    
    /// A signal that emits CBL2CAPChannel object and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses peripheral's `delegate` protocol proxy to observe calls made to `CBPeripheralDelegate.peripheral(_:didOpen:error:)` method.
    @available(iOS 11.0, *)
    public var didOpenChannel: SafeSignal<(CBL2CAPChannel?, Error?)> {
        return delegate.signal(for: #selector(CBPeripheralDelegate.peripheral(_:didOpen:error:))) { (subject: SafePublishSubject<(CBL2CAPChannel?, Error?)>, channel: CBL2CAPChannel?, error: Error?) in
            subject.next((channel, error))
        }
    }
}

#endif
