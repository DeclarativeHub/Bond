//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Christopher-Marcel Böddecker (@bddckr)
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

public extension NSLocale {
  
  public static let currentLocaleObservable = NSNotificationCenter.defaultCenter()
    .bnd_notification(NSCurrentLocaleDidChangeNotification, object: nil)
    .map { _ in NSLocale.autoupdatingCurrentLocale() }
  
  public class func observableOfDisplayNameForKey<Key: AnyObject, Value: AnyObject>(key: Key, value: Value) -> Observable<String?> {
    return NSLocale.currentLocaleObservable.map { $0.displayNameForKey(key, value: value) }
  }
  
  public class func observableOfDisplayNameForKey<Key: AnyObject, Value: AnyObject>(key: Key, valueObservable: Observable<Value>) -> Observable<String?> {
    return NSLocale.currentLocaleObservable
      .combineLatestWith(valueObservable)
      .map { $0.0.displayNameForKey(key, value: $0.1) }
  }
}
