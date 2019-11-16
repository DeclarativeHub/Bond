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

import Foundation
import ReactiveKit

extension NSObject {
    
    /// Bind `signal` to `bindable` and dispose in `bnd_bag` of receiver.
    public func bind<O: SignalProtocol, B: BindableProtocol>(_ signal: O, to bindable: B) where O.Element == B.Element, O.Error == Never {
        signal.bind(to: bindable).dispose(in: bag)
    }
    
    /// Bind `signal` to `bindable` and dispose in `bnd_bag` of receiver.
    public func bind<O: SignalProtocol, B: BindableProtocol>(_ signal: O, to bindable: B) where B.Element: OptionalProtocol, O.Element == B.Element.Wrapped, O.Error == Never {
        signal.bind(to: bindable).dispose(in: bag)
    }
}

internal struct UnownedUnsafe<T: AnyObject> {
    unowned(unsafe) let unbox: T
    init(_ value: T) { unbox = value }
}

extension NSObject {
    
    private struct StaticVariables {
        static var willDeallocateSubject = "WillDeallocateSubject"
        static var swizzledTypes: Set<String> = []
        static var lock = NSRecursiveLock(name: "com.reactivekit.bond.nsobject")
    }
    
    internal var _willDeallocate: Signal<UnownedUnsafe<NSObject>, Never> {
        StaticVariables.lock.lock(); defer { StaticVariables.lock.unlock() }
        if let subject = objc_getAssociatedObject(self, &StaticVariables.willDeallocateSubject) as? ReplayOneSubject<UnownedUnsafe<NSObject>, Never> {
            return subject.toSignal()
        } else {
            let subject = ReplayOneSubject<UnownedUnsafe<NSObject>, Never>()
            subject.send(UnownedUnsafe(self))
            let typeName = String(describing: type(of: self))
            
            if !StaticVariables.swizzledTypes.contains(typeName) {
                StaticVariables.swizzledTypes.insert(typeName)
                type(of: self)._swizzleDeinit { me in
                    if let subject = objc_getAssociatedObject(me, &StaticVariables.willDeallocateSubject) as? ReplayOneSubject<UnownedUnsafe<NSObject>, Never> {
                        subject.send(completion: .finished)
                    }
                }
            }
            
            objc_setAssociatedObject(self, &StaticVariables.willDeallocateSubject, subject, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return subject.toSignal()
        }
    }
    
    private class func _swizzleDeinit(onDeinit: @escaping (NSObject) -> Void) {
        let selector = sel_registerName("dealloc")
        var originalImplementation: IMP? = nil
        
        let swizzledImplementationBlock: @convention(block) (UnsafeRawPointer) -> Void = { me in
            onDeinit(unsafeBitCast(me, to: NSObject.self))
            let superImplementation = class_getMethodImplementation(class_getSuperclass(self), selector)
            if let imp = originalImplementation ?? superImplementation {
                typealias _IMP = @convention(c) (UnsafeRawPointer, Selector) -> Void
                unsafeBitCast(imp, to: _IMP.self)(me, selector)
            }
        }
        
        let swizzledImplementation = imp_implementationWithBlock(swizzledImplementationBlock)
        
        if !class_addMethod(self, selector, swizzledImplementation, "v@:"), let method = class_getInstanceMethod(self, selector) {
            originalImplementation = method_getImplementation(method)
            originalImplementation = method_setImplementation(method, swizzledImplementation)
        }
    }
}
