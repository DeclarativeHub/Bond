//
//  BNDInvocation.swift
//  Bond
//
//  Created by Srdan Rasic on 13/01/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation
import ObjectiveC

#if !BUILDING_WITH_XCODE
    import BNDProtocolProxyBase
#endif

internal extension BNDInvocation {

    func readArgument<T>(_ index: Int) -> T {
        let size = Int(methodSignature.getArgumentSize(at: UInt(index)))
        let alignment = Int(methodSignature.getArgumentAlignment(at: UInt(index)))

        let pointer = UnsafeMutableRawPointer.allocate(bytes: size, alignedTo: alignment)
        getArgument(pointer, at: index)

        defer {
            pointer.deallocate(bytes: size, alignedTo: alignment)
        }

        let type = methodSignature.getArgumentType(at: UInt(index))
        switch type {
        case NSObjCCharType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CChar.self).pointee) as! T
        case NSObjCShortType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CShort.self).pointee) as! T
        case NSObjCIntType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CInt.self).pointee) as! T
        case NSObjCLongType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CLong.self).pointee) as! T
        case NSObjCLonglongType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CLongLong.self).pointee) as! T
        case NSObjCUCharType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CUnsignedChar.self).pointee) as! T
        case NSObjCUShortType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CUnsignedShort.self).pointee) as! T
        case NSObjCUIntType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CUnsignedInt.self).pointee) as! T
        case NSObjCULongType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CUnsignedLong.self).pointee) as! T
        case NSObjCULonglongType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CUnsignedLongLong.self).pointee) as! T
        case NSObjCFloatType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CFloat.self).pointee) as! T
        case NSObjCDoubleType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CDouble.self).pointee) as! T
        case NSObjCBoolType:
            return NSNumber(value: pointer.assumingMemoryBound(to: CBool.self).pointee) as! T
        case NSObjCSelectorType:
            return pointer.assumingMemoryBound(to: Optional<Selector>.self).pointee as! T
        case NSObjCObjectType:
            return pointer.assumingMemoryBound(to: Optional<AnyObject>.self).pointee as! T
        default:
            return pointer.assumingMemoryBound(to: T.self).pointee
        }
    }

    func writeReturnValue<T>(_ value: T) {
        guard methodSignature.methodReturnLength > 0 else { return }

        let size = methodSignature.getReturnArgumentSize()
        let alignment = methodSignature.getReturnArgumentAlignment()
        let type = methodSignature.getReturnArgumentType()

        func write<U, V>(_ value: V, as type: U.Type) {
            let pointer = UnsafeMutablePointer<U>.allocate(capacity: 1)
            pointer.initialize(to: value as! U, count: 1)
            setReturnValue(pointer)
            pointer.deinitialize()
            pointer.deallocate(capacity: 1)
        }

        switch type {
        case NSObjCCharType:
            write(value as! NSNumber, as: CChar.self)
        case NSObjCShortType:
            write(value as! NSNumber, as: CShort.self)
        case NSObjCIntType:
            write(value as! NSNumber, as: CInt.self)
        case NSObjCLongType:
            write(value as! NSNumber, as: CLong.self)
        case NSObjCLonglongType:
            write(value as! NSNumber, as: CLongLong.self)
        case NSObjCUCharType:
            write(value as! NSNumber, as: CUnsignedChar.self)
        case NSObjCUShortType:
            write(value as! NSNumber, as: CUnsignedShort.self)
        case NSObjCUIntType:
            write(value as! NSNumber, as: CUnsignedInt.self)
        case NSObjCULongType:
            write(value as! NSNumber, as: CUnsignedLong.self)
        case NSObjCULonglongType:
            write(value as! NSNumber, as: CUnsignedLongLong.self)
        case NSObjCFloatType:
            write(value as! NSNumber, as: CFloat.self)
        case NSObjCDoubleType:
            write(value as! NSNumber, as: CDouble.self)
        case NSObjCBoolType:
            write(value as! NSNumber, as: CBool.self)
        case NSObjCSelectorType:
            write(value, as: Optional<Selector>.self)
        case NSObjCObjectType:
            write(value, as: Optional<AnyObject>.self)
        default:
            write(value, as: T.self)
        }
    }
}
