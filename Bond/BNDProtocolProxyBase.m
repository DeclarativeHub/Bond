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

- (void)invokeWithSelector:(SEL)selector argumentExtractor:(void (^)(NSInteger index, void *buffer))argumentExtractor setReturnValue:(void (^)(void *buffer))setReturnValue
{
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  if ([self hasHandlerForSelector:invocation.selector]) {
    if (invocation.methodSignature.methodReturnLength > 0) {
      [invocation retainArguments];
      [self invokeWithSelector:invocation.selector argumentExtractor:^(NSInteger index, void *buffer) {
        [invocation getArgument:buffer atIndex:index];
      } setReturnValue:^(void *buffer) {
        [invocation setReturnValue:buffer];
      }];
    } else {
      [self invokeWithSelector:invocation.selector argumentExtractor:^(NSInteger index, void *buffer) {
        [invocation getArgument:buffer atIndex:index];
      } setReturnValue:nil];
    }

    if ([self.forwardTo respondsToSelector:invocation.selector]) {
      [invocation invokeWithTarget:self.forwardTo];
    }
  } else {
    if ([self.forwardTo respondsToSelector:invocation.selector]) {
      [invocation invokeWithTarget:self.forwardTo];
    } else {
      [super forwardInvocation:invocation];
    }
  }
}

@end
