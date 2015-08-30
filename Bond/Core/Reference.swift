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

/// A simple wrapper around an optional that can retain or release given optional at will.
public final class Reference<T: AnyObject> {
  
  /// Encapsulated optional object.
  public weak var object: T?
  
  /// Used to strongly reference (retain) encapsulated object.
  private var strongReference: T?
  
  /// Creates the wrapper and strongly references the given object.
  public init(_ object: T) {
    self.object = object
    self.strongReference = object
  }
  
  /// Relinquishes strong reference to the object, but keeps weak one.
  /// If object it not strongly referenced by anyone else, it will be deallocated.
  public func release() {
    strongReference = nil
  }
  
  /// Re-establishes a strong reference to the object if it's still alive,
  /// otherwise it doesn't do anything useful.
  public func retain() {
    strongReference = object
  }
}
