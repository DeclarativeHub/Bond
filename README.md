# Bond, Swift Bond

[![Platform](https://img.shields.io/cocoapods/p/Bond.svg?style=flat)](http://cocoadocs.org/docsets/Bond/)
[![CI Status](https://travis-ci.org/ReactiveKit/Bond.svg?branch=master)](https://travis-ci.org/ReactiveKit/Bond)
[![Join Us on Gitter](https://img.shields.io/badge/GITTER-join%20chat-blue.svg)](https://gitter.im/ReactiveKit/General)
[![Twitter](https://img.shields.io/badge/twitter-@srdanrasic-red.svg?style=flat)](https://twitter.com/srdanrasic)

<br>
Bond is a Swift binding framework that takes binding concepts to a whole new level. It's simple, powerful, type-safe and multi-paradigm - just like Swift.

Bond is built on top of ReactiveKit and bridges the gap between the reactive and imperative paradigms. You can use it as a standalone framework to simplify your state changes with bindings and reactive data sources, but you can also use it with ReactiveKit to complement your reactive data flows with bindings, reactive delegates and reactive data sources.

Bond is a backbone of the [Binder Architecture](https://github.com/DeclarativeHub/TheBinderArchitecture) - a preferred architecture to be used with the framework.


## Why use Bond?

Say that you would like to do something when text of a text field changes. Well, you could setup the *target-action* mechanism between your objects and go through all that target-action selector registration pain, or you could simply use Bond and do this:

```swift
textField.reactive.text.observeNext { text in
    print(text)
}
```

Now, instead of printing what the user has typed, you can _bind_ it to a label:

```swift
textField.reactive.text.bind(to: label.reactive.text)
```

Because binding to a label text property is so common, you can even do:

```swift
textField.reactive.text.bind(to: label)
```

That one line establishes a binding between the text field's text property and label's text property. In effect, whenever user makes a change to the text field, that change will automatically be propagated to the label.

More often than not, direct binding is not enough. Usually you need to transform input is some way, like prepending a greeting to a name. As Bond is backed by ReactiveKit it has full confidence in functional paradigm.

```swift
textField.reactive.text
  .map { "Hi " + $0 }
  .bind(to: label)
```

Whenever a change occurs in the text field, new value will be transformed by the closure and propagated to the label.

Notice how we have used `reactive.text` property of the fext field. It is an observable representation of the `text` property provided by Bond framework. There are many other extensions like that one for various UIKit components. They are all placed within the `.reactive` proxy.

For example, to observe button events do:

```swift
button.reactive.controlEvents(.touchUpInside)
  .observeNext { e in
    print("Button tapped.")
  }
```

Handling `touchUpInside` event is used so frequently that Bond comes with the extension just for that event:

```swift
button.reactive.tap
  .observeNext {
    print("Button tapped.")
  }  
```

You can use any ReactiveKit operators to transform or combine signals. Following snippet depicts how values of two text fields can be reduced to a boolean value and applied to button's enabled property.

```swift
combineLatest(emailField.reactive.text, passField.reactive.text) { email, pass in
    return email.length > 0 && pass.length > 0
  }
  .bind(to: button.reactive.enabled)
```

Whenever user types something into any of these text fields, expression will be evaluated and button state updated.

Bond's power is not, however, in coupling various UI components, but in the binding of the business logic layer (i.e. Service or View Model) to the View layer and vice-versa. Here is how one could bind user's number of followers property of the model to the label.

```swift
viewModel.numberOfFollowers
  .map { "\($0)" }
  .bind(to: label)
```

Point here is not in the simplicity of a value assignment to the text property of a label, but in the creation of a binding which automatically updates label text property whenever the number of followers change.

Bond also supports two way bindings. Here is an example of how you could keep username text field and username property of your View Model in sync (whenever any of them change, other one will be updated too):

```swift
viewModel.username
  .bidirectionalBind(to: usernameTextField.reactive.text)
```

Bond is also great for observing various different events and asynchronous tasks. For example, you could observe a notification like this:

```swift
NotificationCenter.default.reactive.notification("MyNotification")
  .observeNext { notification in
    print("Got \(notification)")
  }
  .dispose(in: bag)
```

Let me give you one last example. Say you have an array of repositories you would like to display in a collection view. For each repository you have a name and its owner's profile photo. Of course, photo is not immediately available as it has to be downloaded, but once you get it, you want it to appear in collection view's cell. Additionally, when user does 'pull down to refresh' and your array gets new repositories, you want those in collection view too.

So how do you proceed? Well, instead of implementing a data source object, observing photo downloads with KVO and manually updating the collection view with new items, with Bond you can do all that in just few lines:

```swift
repositories.bind(to: collectionView) { array, indexPath, collectionView in
  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! RepositoryCell
  let repository = array[indexPath.item]

  repository.name
    .bind(to: cell.nameLabel)
    .dispose(in: cell.onReuseBag)

  repository.photo
    .bind(to: cell.avatarImageView)
    .dispose(in: cell.onReuseBag)

  return cell
}
```

Yes, that's right!

## Reactive Extensions

Bond is all about bindings and other reactive extensions. To learn more about how bindings work and how to create your own bindings check out [the documentation on bindings](Documentation/Bindings.md).

If you are interested in what bindings and extensions are supported, just start typing `.reactive.` on any UIKit or AppKit object and you will get the list of available extensions. You can also skim over the [source files](https://github.com/DeclarativeHub/Bond/tree/master/Sources/Bond/UIKit) to get an overview.

## Observable Collections

When working with arrays usually we need to know how exactly did an array change. New elements could have been inserted into the array and old ones deleted or updated. Bond provides mechanisms for observing such fine-grained changes.

For example, Bond provides you with a `(Mutable)ObservableArray` type that can be used to generate and observe fine-grained changes.

```swift
let names = MutableObservableArray(["Steve", "Tim"])

...

names.observeNext { e in
  print("array: \(e.source), change: \(e.change)")
}
```

You work with the observable array like you would work with the array it encapsulates.

```swift
names.append("John") // prints: array ["Steve", "Tim", "John"], change: .inserts([2])
names.removeLast()   // prints: array ["Steve", "Tim"], change: .deletes([2])
names[1] = "Mark"    // prints: array ["Steve", "Mark"], change: .updates([1])
```

Peek into [observable collections documentation](Documentation/ObservableCollections.md) to learn more about observable collections.

## Data Source Signals

Observable collections and other data source signals enable us to build powerful UI bindings. For example, an observable array could be bound to a collection view just like this:

```swift
names.bind(to: collectionView, cellType: UserCell.self) { (cell, name) in
    cell.titleLabel.text = name
}
```

No need to implement data source objects and do everything manually. Check out [documentation on the data source signals](Documentation/DataSourceSignals.md) to learn more about them and about table or collection view bindings. 

## Protocol Proxies

Bond provides `NSObject` extensions that make it easy to convert delegate method calls into signal. The extensions are built on top of ObjC runtime and enable you to intercept delegate method invocations and convert them into signal events.

Bond uses protocol proxies to implement table and collection view bindings and to provide signals like `tableView.reactive.selectedRowIndexPath`. Check out [the protocol proxies documentation](Documentation/ProtocolProxies.md) to learn more.


## Requirements

* iOS 8.0+ / macOS 10.9+ / tvOS 9.0+
* Xcode 9

## Communication

* If you'd like to ask a general question, use Stack Overflow.
* If you'd like to ask a quick question or chat about the project, try [Gitter](https://gitter.im/ReactiveKit/General).
* If you found a bug, open an issue.
* If you have a feature request, open an issue.
* If you want to contribute, submit a pull request (include unit tests).

## Installation

### Carthage

1. Add the following to your *Cartfile*:
  <br> `github "DeclarativeHub/Bond"`
2. Run `carthage update`
3. Add the framework as described in [Carthage Readme](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

### CocoaPods

1. Add the following to your *Podfile*:
  <br> `pod 'Bond'`
2. Run `pod install`.

## License

The MIT License (MIT)

Copyright (c) 2015-2018 Srdan Rasic (@srdanrasic)

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
