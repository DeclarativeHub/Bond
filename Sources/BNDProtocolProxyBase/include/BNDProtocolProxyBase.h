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

#import <Foundation/Foundation.h>

enum BNDNSObjCValueType {
    NSObjCNoType = 0,
    NSObjCVoidType = 'v',
    NSObjCCharType = 'c',
    NSObjCShortType = 's',
    NSObjCIntType = 'i',
    NSObjCLongType = 'l',
    NSObjCLonglongType = 'q',
    NSObjCUCharType = 'C',
    NSObjCUShortType = 'S',
    NSObjCUIntType = 'I',
    NSObjCULongType = 'L',
    NSObjCULonglongType = 'Q',
    NSObjCFloatType = 'f',
    NSObjCDoubleType = 'd',
    NSObjCBoolType = 'B',
    NSObjCSelectorType = ':',
    NSObjCObjectType = '@',
    NSObjCStructType = '{',
    NSObjCPointerType = '^',
    NSObjCStringType = '*',
    NSObjCArrayType = '[',
    NSObjCUnionType = '(',
    NSObjCBitfield = 'b'
};

@interface BNDMethodSignature: NSObject

@property (readonly) NSUInteger numberOfArguments;
- (enum BNDNSObjCValueType)getArgumentTypeAtIndex:(NSUInteger)idx;
- (NSUInteger)getArgumentAlignmentAtIndex:(NSUInteger)idx;
- (NSUInteger)getArgumentSizeAtIndex:(NSUInteger)idx;

@property (readonly) NSUInteger frameLength;

- (BOOL)isOneway;

@property (readonly) const char * _Nonnull methodReturnType;
@property (readonly) NSUInteger methodReturnLength;

- (enum BNDNSObjCValueType)getReturnArgumentType;
- (NSUInteger)getReturnArgumentSize;
- (NSUInteger)getReturnArgumentAlignment;

@end

@interface BNDInvocation: NSObject

@property (readonly, nonnull) BNDMethodSignature * methodSignature;

- (void)retainArguments;

@property (readonly) BOOL argumentsRetained;

@property (nonnull, readonly) SEL selector;

- (void)getReturnValue:(void * _Nonnull)retLoc;
- (void)setReturnValue:(void * _Nonnull)retLoc;

- (void)getArgument:(void * _Nonnull)argumentLocation atIndex:(NSInteger)idx;
- (void)setArgument:(void * _Nonnull)argumentLocation atIndex:(NSInteger)idx;

@end

@interface BNDProtocolProxyBase : NSObject

@property (nonatomic, readonly, nonnull, strong) Protocol *protocol;

/// An object conforming to protocol `protocol` to which forward methods calls.
@property (nonatomic, nullable, weak) NSObject *forwardTo;

- (nonnull instancetype)initWithProtocol:(nonnull Protocol *)protocol;
- (BOOL)hasHandlerForSelector:(nonnull SEL)selector;
- (void)handleInvocation:(nonnull BNDInvocation *)invocation;
@end
