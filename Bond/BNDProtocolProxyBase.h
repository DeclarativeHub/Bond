//
//  RKDelegate.h
//  ReactiveKit
//
//  Created by Srdan Rasic on 14/05/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKProtocolProxyBase : NSObject

@property (nonatomic, readonly, nonnull, strong) Protocol *protocol;

/// An object conforming to protocol `protocol` to which forward methods calls.
@property (nonatomic, nullable, weak) NSObject *forwardTo;

- (nonnull instancetype)initWithProtocol:(nonnull Protocol *)protocol;
- (BOOL)hasHandlerForSelector:(nonnull SEL)selector;
- (void)invokeWithSelector:(nonnull SEL)selector argumentExtractor:(void (^_Nonnull)(NSInteger index, void * _Nullable buffer))argumentExtractor setReturnValue:(void (^_Nullable)(void * _Nullable buffer))setReturnValue;

@end
