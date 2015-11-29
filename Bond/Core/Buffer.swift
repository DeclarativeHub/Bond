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

import Foundation

/// A simple collection that buffers latest `size` values.
public struct Buffer<EventType> {
  
  /// Internal buffer
  internal var buffer: [EventType] = []
  
  /// Buffer size
  public var size: Int
  
  /// Last event pushed into the buffer
  public var last: EventType? {
    return buffer.last
  }
  
  /// Creates a new buffer of given size
  public init(size: Int) {
    guard size > 0 else {
      fatalError("Dear Sir/Madam, buffer has to have the size of least 1.")
    }
    
    self.size = size
    buffer.reserveCapacity(size)
  }
  
  /// Adds the given element to the buffer. If the buffer is already
  /// at its capacity, it will discard the oldest element.
  public mutating func push(event: EventType) {
    if size == 1 {
      if buffer.count == 0 {
        buffer.append(event)
      } else {
        buffer[0] = event;
      }
    } else {
      buffer.append(event)
      if buffer.count > size {
        buffer.removeFirst()
      }
    }
  }
  
  public func replayTo(sink: EventType -> Void) {
    for event in buffer {
      sink(event)
    }
  }
}
