//
//  CBCentralManager.swift
//  Bond
//
//  Created by Pavlo Naumenko on 3/1/19.
//  Copyright © 2019 Swift Bond. All rights reserved.
//

import CoreBluetooth
import ReactiveKit

#if os(iOS) || os(tvOS)

public extension ReactiveExtensions where Base: CBCentralManager {
    
    /// A `ProtocolProxy` for the central manager delegate.
    ///
    /// - Note: Accessing this property for the first time will replace central manager's current delegate
    /// with a protocol proxy object (an object that is stored in this property).
    /// Current delegate will be used as `forwardTo` delegate of protocol proxy.
    public var delegate: ProtocolProxy {
        return protocolProxy(for: CBCentralManagerDelegate.self, keyPath: \.delegate)
    }
    
    /// A signal that emits central manager state.
    ///
    /// - Note: Uses central manager's `delegate` protocol proxy to observe calls made to `CBCentralManagerDelegate.centralManagerDidUpdateState(_:)` method.
    @available(iOS 10.0, *)
    public var didUpdateState: SafeSignal<CBManagerState> {
        return delegate.signal(for: #selector(CBCentralManagerDelegate.centralManagerDidUpdateState(_:))) { (subject: SafePublishSubject<CBManagerState>, central: CBCentralManager) in
            subject.next(central.state)
        }
    }
    
    /// A signal that emits a dictionary containing information about <i>central</i> that was preserved by the system at the time the app was terminated.
    ///
    /// - Note: Uses central manager's `delegate` protocol proxy to observe calls made to `CBCentralManagerDelegate.centralManager(_:willRestoreState:)` method.
    @available(iOS 5.0, *)
    public var willRestoreState: SafeSignal<[String : Any]> {
        return delegate.signal(for: #selector(CBCentralManagerDelegate.centralManager(_:willRestoreState:))) { (subject: SafePublishSubject<[String : Any]>, central: CBCentralManager, dict: [String : Any]) in
            subject.next(dict)
        }
    }
    
    /// A signal that emits a CBPeripheral object with a dictionary containing any advertisement and scan response data and also current RSSI of peripheral, in dBm.
    ///
    /// - Note: Uses central manager's `delegate` protocol proxy to observe calls made to `CBCentralManagerDelegate.centralManager(_:didDiscover:advertisementData:rssi:)` method.
    @available(iOS 5.0, *)
    public var didDiscoverPeripheral: SafeSignal<(CBPeripheral, [String : Any], NSNumber)> {
        return delegate.signal(for: #selector(CBCentralManagerDelegate.centralManager(_:didDiscover:advertisementData:rssi:))) { (subject: SafePublishSubject<(CBPeripheral, [String : Any], NSNumber)>,
            central: CBCentralManager,
            peripheral: CBPeripheral,
            advertisementData: [String : Any],
            RSSI: NSNumber) in
            subject.next((peripheral, advertisementData, RSSI))
        }
    }
    
    /// A signal that emits the CBPeripheral that has connected.
    ///
    /// - Note: Uses central manager's `delegate` protocol proxy to observe calls made to `CBCentralManagerDelegate.centralManager(_:didConnect:)` method.
    @available(iOS 5.0, *)
    public var  didConnectPeripheral: SafeSignal<CBPeripheral> {
        return delegate.signal(for: #selector(CBCentralManagerDelegate.centralManager(_:didConnect:))) { (subject: SafePublishSubject<CBPeripheral>, central: CBCentralManager, peripheral: CBPeripheral) in
            subject.next(peripheral)
        }
    }
    
    /// A signal that emits the CBPeripheral that has failed to connect and the cause of the failure.
    ///
    /// - Note: Uses central manager's `delegate` protocol proxy to observe calls made to `CBCentralManagerDelegate.centralManager(_:didFailToConnect:error:)` method.
    @available(iOS 5.0, *)
    public var didFailToConnectPeripheral: SafeSignal<(CBPeripheral, Error?)> {
        return delegate.signal(for: #selector(CBCentralManagerDelegate.centralManager(_:didFailToConnect:error:))) { (subject: SafePublishSubject<(CBPeripheral, Error?)>, peripheral: CBPeripheral, error: Error?) in
            subject.next((peripheral, error))
        }
    }
    
    /// A signal that emits the CBPeripheral that has disconnected and if an error occurred, the cause of the failure.
    ///
    /// - Note: Uses central manager's `delegate` protocol proxy to observe calls made to `CBCentralManagerDelegate.centralManager(_:didDisconnectPeripheral:error:)` method.
    @available(iOS 5.0, *)
    public var didDisconnectPeripheralPeripheral: SafeSignal<(CBPeripheral, Error?)> {
        return delegate.signal(for: #selector(CBCentralManagerDelegate.centralManager(_:didDisconnectPeripheral:error:))) { (subject: SafePublishSubject<(CBPeripheral, Error?)>, peripheral: CBPeripheral, error: Error?) in
            subject.next((peripheral, error))
        }
    }
}

#endif
