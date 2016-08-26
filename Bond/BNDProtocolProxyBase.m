//
//  RKDelegate.m
//  ReactiveKit
//
//  Created by Srdan Rasic on 14/05/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

#import "BNDProtocolProxyBase.h"
#import <objc/runtime.h>

@interface RKProtocolProxyBase ()
@property (nonatomic, readwrite, strong) Protocol *protocol;
@end

@implementation RKProtocolProxyBase

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
