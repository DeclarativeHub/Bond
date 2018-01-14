//
//  ProtocolProxyController.swift
//  Bond
//
//  Created by Srdan Rasic on 14/01/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public class ProtocolProxyPropertyController: NSObject {
    public weak var object: NSObject?
    public var delegate: NSObject?

    public init(object: NSObject) {
        self.object = object
    }
}

public final class KeyPathProtocolProxyPropertyController<Root: NSObject, P>: ProtocolProxyPropertyController {

    private weak var _object: Root?
    private let keyPath: ReferenceWritableKeyPath<Root, P>

    public init(object: Root, keyPath: ReferenceWritableKeyPath<Root, P>) {
        self._object = object
        self.keyPath = keyPath
        super.init(object: object)
    }

    public override var delegate: NSObject? {
        get {
            return _object?[keyPath: keyPath] as? NSObject
        }
        set {
            if let newValue = newValue as? P {
                _object?[keyPath: keyPath] = newValue
            }
        }
    }

    public override var hash: Int {
        return keyPath.hashValue
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? KeyPathProtocolProxyPropertyController<Root, P> else {
            return false
        }
        return keyPath == other.keyPath && _object === other._object
    }
}

public final class OptionalKeyPathProtocolProxyPropertyController<Root: NSObject, P>: ProtocolProxyPropertyController {

    private weak var _object: Root?
    private let keyPath: ReferenceWritableKeyPath<Root, P?>

    public init(object: Root, keyPath: ReferenceWritableKeyPath<Root, P?>) {
        self._object = object
        self.keyPath = keyPath
        super.init(object: object)
    }

    public override var delegate: NSObject? {
        get {
            return _object?[keyPath: keyPath] as? NSObject
        }
        set {
            _object?[keyPath: keyPath] = newValue as? P
        }
    }

    public override var hash: Int {
        return keyPath.hashValue
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? OptionalKeyPathProtocolProxyPropertyController<Root, P> else {
            return false
        }
        return keyPath == other.keyPath && _object === other._object
    }
}

public final class SelectorProtocolProxyPropertyController: ProtocolProxyPropertyController {

    private let selector: Selector

    public init(object: NSObject, selector: Selector) {
        self.selector = selector
        super.init(object: object)
    }

    public override var delegate: NSObject? {
        get {
            return nil
        }
        set {
            _ = object?.perform(selector, with: newValue)
        }
    }

    public override var hash: Int {
        return selector.hashValue
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SelectorProtocolProxyPropertyController else {
            return false
        }
        return selector == other.selector && self.object === other.object
    }
}
