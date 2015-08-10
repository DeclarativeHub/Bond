# Bond, Rx Bond

[![CI Status](https://travis-ci.org/SwiftBond/Bond.svg?branch=master)](https://travis-ci.org/SwiftBond/Bond)

Bond is a Swift binding framework that takes binding concept to a whole new level. It's simple, powerful, type-safe and multi-paradigm - just like Swift. 

Bond was created with two goals in mind: simple to use and simple to understand. One might argue whether the former implies the latter, but Bond will save you some thinking because both are true in this case. Its foundation are two simple classes - everything else are extensions and syntactic sugars.



## What can it do?

```swift
textField.bnd_text.observe { text in 
  print(text)
}
```

```swift
textField.bnd_text.bindTo(label.bnd_text)
textField.bnd_text |> label.bnd_text
```

```swift
textField.bnd_text.map { "Hi " + $0 } |> label.bnd_text
```

```swift
textField.bnd_text.filter { count($0) > 3 } |> label.bnd_text
```


```swift
combineLatest(emailField.bnd_text, passField.bnd_text) { email, pass in
  count(email) > 0 && count(pass) > 0
} |> loginButton.bnd_enabled
```

```swift
viewModel.numberOfFollowers.map { "\($0)" } |> label.bnd_text
```

```swift
viewModel.username |>< usernameTextField.bnd_text
```

```swift
loginButton.bnd_tap.observe {
  print("Hi")
}
```

```swift
let disposable = loginButton.bnd_tap.observe {
  print("Hi")
}

disposable.dispose()
```

```swift
let collectionView = UICollectionView()
let data = Vector([Vector([1, 2, 3]), Vector([10, 20, 30])])

data.bindTo(collectionView, createCell: { (indexPath, vector, collectionView) -> UICollectionViewCell in
  return collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
})
```

```swift
NSNotificationCenter.defaultCenter().bnd_notification("MyNotification").observe { notification in
  print("Got \(notification)")
}
```

```swift
NSURLSession.sharedSession().bnd_dataWithURL(NSURL(string: "http://example.com/my-data")!).onSuccess { data in
  print("Got data \(data)")
}
```

```swift
searchTextField.bnd_text
  .throttle(0.3, queue: Queue.Main)
  .distinct()
  .map(searchResultsForQuery)
  .switchToLatest()
  .onSuccess { results in
    print("Got results: \(results)")
  }
    
// given that:

  func searchResultsForQuery(query: String) -> Promise<[String], NSError>
```

## How does it work?

```swift
public protocol ObservableType {
  typealias EventType
  func observe(observer: EventType -> Void) -> DisposableType
}
```

```swift
public class Observable<EventType>: ObservableType {
}
```

```swift
public final class Scalar<ValueType>: Observable<ValueType>, ScalarType, BindableType {
  var value: ValueType
}
```

```swift
public final class Vector<ElementType>: Observable<VectorEvent<ElementType>>, VectorType {
  public var array: [ElementType]
  public func performBatchUpdates(@noescape update: Vector<ElementType> -> ())
}
```

```swift
public final class Promise<SuccessType, FailureType: ErrorType>: Observable<Future<SuccessType, FailureType>> {
  public func success(value: SuccessType)
  public func failure(error: FailureType)
}
```


## Installation

### Carthage

1. Add the following to your *Cartfile*:
  <br> `github "SwiftBond/Bond" ~> 4.0`
2. Run `carthage update`
3. Add the framework as described in [Carthage Readme](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)


### CocoaPods

1. Add the following to your *Podfile*:
  <br> `pod 'Bond', '~> 4.0'`
2. Run `pod install` with CocoaPods 0.36 or newer.

### Git Submodules

1. Clone Bond as a submodule into the directory of your choice
  <br> `git submodule add git@github.com:SwiftBond/Bond.git`
  <br> `git submodule update --init`
2. Drag Bond.xcodeproj into your project tree as a subproject
3. Under your project's Build Phases, expand Target Dependencies
4. Click the + and add Bond
5. Expand the Link Binary With Libraries phase
6. Click the + and add Bond
7. Click the + at the top left corner to add a Copy Files build phase
8. Set the directory to Frameworks
9. Click the + and add Bond

### Standalone

Just get *.swift* files from Bond/ Directory and add them to your project.


## Release Notes

https://github.com/SwiftBond/Bond/releases


## License

The MIT License (MIT)

Copyright (c) 2015 Srdan Rasic (@srdanrasic)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

