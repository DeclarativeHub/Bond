# Bond, Swift Bond

[![CI Status](https://travis-ci.org/SwiftBond/Bond.svg?branch=master)](https://travis-ci.org/SwiftBond/Bond)

Bond is a Swift binding framework that takes binding concept to a whole new level. It's simple, powerful, type-safe and multi-paradigm - just like Swift. 

Bond was created with two goals in mind: simple to use and simple to understand. One might argue whether the former implies the latter, but Bond will save you some thinking because both are true in this case. Its foundation are few simple classes - everything else are extensions and syntactic sugars.

**Note: This document describes Bond v4. If you are using a previous version of the framework, check out the [Migration to Bond v4](#migration) section. Bond v4 will be the only officially supported version for Swift 2.0.**


## What can it do?

Say you'd like to act on a text change event of a UITextField. Well, you could setup 'target-action' mechanism between your object and go through all that target-action selector registration pain, or you could simply use Bond and do this:

```swift
textField.bnd_text
  .observe { text in
    print(text)
  }
```

Now, instead of printing what user has typed, you could even _bind_ it to a UILabel:

```swift
textField.bnd_text
  .bindTo(label.bnd_text)
```

That one line establishes a binding between text field's text property and label's text property. In effect, whenever user makes a change to the text field, that change will be automatically propagated to the label.

More often than not, direct binding is not enough. Usually you need to transform input is some way, like prepending a greeting to a name. Of course, Bond has full confidence in functional paradigm.


```swift
textField.bnd_text
  .map { "Hi " + $0 }
  .bindTo(label.bnd_text)
```

Whenever a change occurs in the text field, new value will be transformed by the closure and propagated to the label.

Notice how we've used `bnd_text` property of the UITextField. It's an observable representation of the `text` property provided by Bond framework. There are many other extensions like that one for various UIKit components. Just start typing _.bnd_ on any UIKit object and you'll get the list of available extensions.

In addition to `map`, another important functional construct is `filter` function. It's useful when we are interested only in some values of a domain. For example, when observing events of a button, we might be interested only in `TouchUpInside` event so we can perform certain action when user taps the button:

```swift
button.bnd_controlEvent
  .filter { $0 == UIControlEvents.TouchUpInside }
  .observe { e in
    print("Button tapped.")
  }
```

Handling `TouchUpInside` event is used so frequently that Bond comes with the extension just for that event:

```swift
button.bnd_tap
  .observe {
    print("Button tapped.")
  }  
```

Bond can also combine multiple inputs into a single output. Following snippet depicts how values of two text fields can be reduced to a boolean value and applied to button's enabled property.

```swift
combineLatest(emailField.bnd_text, passField.bnd_text)
  .map { email, pass in
    return email.length > 0 && pass.length > 0
  }
  .bindTo(button.bnd_enabled)
```

Whenever user types something into any of these text fields, expression will be evaluated and button state updated.

Bond's power is not, however, in coupling various UI components, but in the binding of a Model (or a ViewModel) to a View and vice-versa. It's great for MVVM paradigm. Here is how one could bind user's number of followers property of the model to the label.

```swift
viewModel.numberOfFollowers
  .map { "\($0)" }
  .bindTo(label.bnd_text)
```

Point here is not in the simplicity of value assignment to text property of a label, but in the creation of a binding which automatically updates label text property whenever number of followers change.

Bond also supports two way bindings. Here is an example of how you could keep username text field and username property of your view model in sync (whenever any of them change, other one will be updated too):

```swift
viewModel.username.bidirectionalBindTo(usernameTextField.bnd_text)
```

Bond is also great for observing various different events and asynchronous task. For example, you could observe a notification just like this:

```swift
NSNotificationCenter.defaultCenter().bnd_notification("MyNotification")
  .observe { notification in
    print("Got \(notification)")
  }
  .disposeIn(bnd_bag)
```

Let me give you one last example. Say you have an array of repositories you would like to display in a collection view. For each repository you have a name and its owner's profile photo. Of course, photo is not immediately available as it has to be downloaded, but once you get it, you want it to appear in table view's cell. Additionally, when user does 'pull down to refresh', and your array gets new repositories, you want those in table view too.

So how do you proceed? Well, instead of implementing a data source object, observing photo downloads with KVO and manually updating table view with new items, with Bond you can do all that in just few lines:

```swift
repositories.bindTo(collectionView, createCell: { (indexPath, array, collectionView) -> UICollectionViewCell in
  let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! RepositoryCell
  let repository = array[indexPath.section][indexPath.item]
  repository.name.bindTo(cell.nameLabel.bnd_text)
  repository.photo.bindTo(cell.avatarImageView.bnd_image)
  return cell
})
```

Yes, that's right!


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
public final class ObservableArray<ElementType>: Observable<ObservableArrayEvent<ElementType>>, ObservableArrayType {
  public var array: [ElementType]
  public func performBatchUpdates(@noescape update: ObservableArray<ElementType> -> ())
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


<a name="migration"></a>
## Migration to Bond v4


Bond v4 represents a major evolution of the framework. It's core has been rewritten from scratch and, while concepts are still pretty much the same, some things have changed from the outside to. In order to successfully upgrade your project to Bond v4, it is recommended to re-read this document. After that, you can proceed with the conversion: 

### Dynamic become **Observable**

Convert objects of `Dynamic` type to `Observable` type. Simple renaming should do the trick. 

### DynamicArray become **ObservableArray**

Convert objects of `DynamicArray` type to `ObservableArray` type. Simple renaming should do the trick. 

### Bond and ArrayBond are deprecated

Bonds were used to observe changes of a Dynamic. With Bond v4, observing changes is much simpler. Instead of creating a new object, you can now use `observe` method on any Observable type. In other words, code like

```swift
let myBond = Bond<Int>() { value in
  print("Number of followers changed to \(value).")
}

numberOfFollowers.bindTo(myBond)
```

becomes

```swift
numberOfFollowers.observe { value in
  println("Number of followers changed to \(value).")
}
```

To cancel observing in v3 you have used `unbindAll` method on the Bond. In v4, cancelling the observation or unbinding the object is done with a *disposable*. Methods `observe` and `bindTo` return an object of a Disposable type. You can use that object to cancel observing, like this:

```swift
let disposable = numberOfFollowers.observe { value in
  println("Number of followers changed to \(value).")
}

// ... and if you wish to cancel observing later, just call:
disposable.dispose()
```

Observing ObservableArrays is similar. Instead of calling various closures like DynamicArray did in v3, ObservableArray in v4 is an Observable that sends events that describe operation that was just applied to the ObservableArray. You can observe those in a following way:

```swift
array.observe { event in
 switch event.operation {
 case .Insert(let elements, let fromIndex):
   // Did insert elements
 case .Update(let elements, let fromIndex):
   // Did update elements
 case .Remove(let range):
   // Did remove elements
 case .Reset(let array):
   // Did replace whole array with the another array
 case .Batch(let operations):
   // Did perform batch updates
 }
}
```

### Extension are now prefixed with `bnd_`

In Bond v3, extensions were prefixed with `dyn`, like in `textField.dynText`. As Dynamics are now gone it makes no sense to keep that prefix. In v4 all extensions provided by Bond framework are prefixed with `bnd_`.

### Designated Dynamics are gone

While in Bond v3 you were able to bind, for example, a boolean Dynamic to a button,

```swift
canLogin.bindTo(loginButton)
```

it would not be clear from that line of code where you were really binding the value to. In Bond v4 you have to be specific and always provide a bindable destination, like:


```swift
canLogin.bindTo(loginButton.bnd_enabled)
```
 
Hope is that this will reduce any confusion and improve the code readability.

### Method `bindTo` is now preferred way to bind objects

Talking about the code readability, another important decision has been made. In order to clearly express action behind a line of the code, method `bindTo` has become a preferred way to bind objects. Operators `->>` and `->><` are still available, but their usage is not recommended. 


### _Bind only_ operator `->|` is gone

You can use method `observeNew` to observe only events that happen after the binding took place. Alternatively, you can use `skip` method to skip event replaying:

```swift
name.skip(name.replayLength).bindTo(nameLabel.bnd_text)
```

### Method `reduce` is deprecated

What method `reduce` did in v3 can now be achieved with a combination of `combineLatest` and `map` methods.

```swift
combineLatest(userLabel.bnd_text, passLabel.bnd_text).map { user, pass in
  // do something
}
```
 
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

