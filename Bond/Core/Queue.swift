//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
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

import Dispatch
import Foundation

/// A simple wrapper around GCD queue.
public struct Queue {
  
  public typealias TimeInterval = NSTimeInterval
  
  public static let Main = Queue(queue: dispatch_get_main_queue());
  public static let Default = Queue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
  public static let Background = Queue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
  
  public private(set) var queue: dispatch_queue_t

  public init(queue: dispatch_queue_t = dispatch_queue_create("com.swift-bond.Bond.Queue", DISPATCH_QUEUE_SERIAL)) {
    self.queue = queue
  }
  
  public func after(interval: NSTimeInterval, block: () -> Void) {
    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * NSTimeInterval(NSEC_PER_SEC)))
    dispatch_after(dispatchTime, queue, block)
  }
  
  public func async(block: () -> Void) {
    dispatch_async(queue, block)
  }

  public func sync(block: () -> Void) {
    dispatch_sync(queue, block)
  }
}
