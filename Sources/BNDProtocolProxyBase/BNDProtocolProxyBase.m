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

#import "BNDProtocolProxyBase.h"
#import <objc/runtime.h>

@interface BNDMethodSignature ()
@property (nonatomic, strong) NSMethodSignature *signature;
@end

@interface BNDInvocation ()
@property (nonatomic, strong) NSInvocation *invocation;
@property (nonatomic, strong) BNDMethodSignature *signature;
- (instancetype)initWithInvocation:(NSInvocation *)invocation;
@end


@interface BNDProtocolProxyBase ()
@property (nonatomic, readwrite, strong) Protocol *protocol;
@end

@implementation BNDProtocolProxyBase

- (instancetype)initWithProtocol:(Protocol *)protocol
{
    self = [super init];
    if (self) {
        _protocol = protocol;
    }
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];

    if (!signature && [self hasHandlerForSelector:selector]) {
        struct objc_method_description description = protocol_getMethodDescription(self.protocol, selector, NO, YES);
        if (description.types == NULL) {
            description = protocol_getMethodDescription(self.protocol, selector, YES, YES);
        }
        signature = [NSMethodSignature signatureWithObjCTypes:description.types];
    }

    if (!signature) {
        signature = [self.forwardTo methodSignatureForSelector:selector];
    }

    return signature;
}

- (BOOL)hasHandlerForSelector:(SEL)selector
{
    return NO;
}

- (void)handleInvocation:(BNDInvocation *)invocation
{
    // Overridden in Swift subclass
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([self hasHandlerForSelector:invocation.selector]) {
        [self handleInvocation:[[BNDInvocation alloc] initWithInvocation:invocation]];
    } else if ([self.forwardTo respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.forwardTo];
    } else {
        [super forwardInvocation:invocation];
    }
}

@end

@implementation BNDMethodSignature

- (instancetype)initWithMethodSignature:(NSMethodSignature *)methodSignature
{
    self = [super init];
    if (self) {
        _signature = methodSignature;
    }
    return self;
}

- (NSUInteger)numberOfArguments {
    return self.signature.numberOfArguments;
}

- (enum BNDNSObjCValueType)getArgumentTypeAtIndex:(NSUInteger)idx {
    return [self.signature getArgumentTypeAtIndex:idx][0];
}

- (NSUInteger)getArgumentSizeAtIndex:(NSUInteger)idx {
    NSUInteger size;
    NSGetSizeAndAlignment([self.signature getArgumentTypeAtIndex:idx], &size, NULL);
    return size;
}

- (NSUInteger)getArgumentAlignmentAtIndex:(NSUInteger)idx {
    NSUInteger alignment;
    NSGetSizeAndAlignment([self.signature getArgumentTypeAtIndex:idx], NULL, &alignment);
    return alignment;
}

- (NSUInteger)frameLength {
    return self.signature.frameLength;
}

- (BOOL)isOneway {
    return [self.signature isOneway];
}

- (const char *)methodReturnType {
    return [self.signature methodReturnType];
}

- (NSUInteger)methodReturnLength {
    return self.signature.methodReturnLength;
}

- (enum BNDNSObjCValueType)getReturnArgumentType {
    return [self methodReturnType][0];
}

- (NSUInteger)getReturnArgumentSize {
    NSUInteger size;
    NSGetSizeAndAlignment(self.methodReturnType, &size, NULL);
    return size;
}

- (NSUInteger)getReturnArgumentAlignment {
    NSUInteger alignment;
    NSGetSizeAndAlignment(self.methodReturnType, NULL, &alignment);
    return alignment;
}

@end

@implementation BNDInvocation

- (instancetype)initWithInvocation:(NSInvocation *)invocation
{
    self = [super init];
    if (self) {
        _invocation = invocation;
        _signature = [[BNDMethodSignature alloc] initWithMethodSignature:[invocation methodSignature]];
    }
    return self;
}

- (BNDMethodSignature *)methodSignature {
    return self.signature;
}

- (void)retainArguments {
    [self.invocation retainArguments];
}

- (BOOL)argumentsRetained {
    return [self.invocation argumentsRetained];
}

- (SEL)selector {
    return [self.invocation selector];
}

- (void)getReturnValue:(void *)retLoc {
    [self.invocation getReturnValue:retLoc];
}

- (void)setReturnValue:(void *)retLoc {
    [self.invocation setReturnValue:retLoc];
}

- (void)getArgument:(void *)argumentLocation atIndex:(NSInteger)idx {
    [self.invocation getArgument:argumentLocation atIndex:idx];
}

- (void)setArgument:(void *)argumentLocation atIndex:(NSInteger)idx {
    [self.invocation setArgument:argumentLocation atIndex:idx];
}

@end
