# Bond, Swift Bond

[![CI Status](https://travis-ci.org/SwiftBond/Bond.svg?branch=master)](https://travis-ci.org/SwiftBond/Bond)

Bond is a Swift binding framework that takes binding concept to a whole new level. It's simple, powerful, type-safe and multi-paradigm - just like Swift. 

Bond was created with two goals in mind: simple to use and simple to understand. One might argue whether the former implies the latter, but Bond will save you some thinking because both are true in this case. Its foundation are few simple classes - everything else are extensions and syntactic sugars.

**Note: This document describes Bond v4. If you are using a previous version of the framework, check out the [Migration to Bond v4](#migration) section. Bond v4 is the only officially supported version for Swift 2.0.**


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

Bond is also great for observing various different events and asynchronous tasks. For example, you could observe a notification just like this:

```swift
NSNotificationCenter.defaultCenter().bnd_notification("MyNotification")
  .observe { notification in
    print("Got \(notification)")
  }
  .disposeIn(bnd_bag)
```

Let me give you one last example. Say you have an array of repositories you would like to display in a collection view. For each repository you have a name and its owner's profile photo. Of course, photo is not immediately available as it has to be downloaded, but once you get it, you want it to appear in collection view's cell. Additionally, when user does 'pull down to refresh' and your array gets new repositories, you want those in collection view too.

So how do you proceed? Well, instead of implementing a data source object, observing photo downloads with KVO and manually updating the collection view with new items, with Bond you can do all that in just few lines:

```swift
repositories.bindTo(collectionView) { indexPath, array, collectionView in
  let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! RepositoryCell
  let repository = array[indexPath.section][indexPath.item]
  
  repository.name
    .bindTo(cell.nameLabel.bnd_text)
    .disposeIn(cell.onReuseBag)
    
  repository.photo
    .bindTo(cell.avatarImageView.bnd_image)
    .disposeIn(cell.onReuseBag)

  return cell
})
```

Yes, that's right!


## The Event Producer

At the core of the framework is the class `EventProducer`. It represents an abstract event generator that provides the mechanisms that enable interested parties, called *observers*, to observe generated events. For example, it can be used to represent a subject with a mutable state, like a variable or an array, and then inform observers of the state change whenever it happens. On the other hand it can represent an action, something without a state, and generate an event whenever the action occurs.

### The Observable

The most common use of the event producer is through its subclass `Observable` that can mimic a variable or a property and enable observation of its change. The Observable is a generic type generalized over the wrapped value type. As the EventProducer is also a generic type, generalized over its event type, it is only natural to specialize such event producer to the type of the values it can encapsulate. To create the observable just initialize it with a value:

```swift
let captain = Observable(“Jim”)
```

Swift automatically infers the type of the observable from the passed value. In our example the type of the variable `captain` is `Observable<String>`. To change its value afterwards, you can use the method `next`:

```swift
captain.next(“Spock”)
```

The value is accessible through the property `value`:

```swift
print(captain.value) // prints: Spock
```

The property is both a getter that returns the observable’s value and a setter that updates the observable with a new value just like the method `next`. 

Now comes the interesting part. In order to make the observable useful it should be observed. Observing the observable means observing the events it generates, that is, in our case, the values that are being set. To observe the observable we register a closure of the type `EventType -> ()` to it with the method observe, where *EventType* is the event (value) type:

```swift
captain.observe { name in
  print(“Now the captain is \(name).”)
}

// prints: Now the captain is Spock.
```

The closure will be called at the time of the registration with the value currently set to the observable. If you are not interested in the current value, but only in the new ones, you can use the method `observeNew` instead.

Now, whenever the value is changed, the observer closure will be called and side effects performed:

```swift
captain.next(“Scotty” ) // prints: Now the captain is Scotty.
```

which is same as:

```swift
captain.value = “Scotty” // prints: Now the captain is Scotty.
```

### The Event Producer

Using the observable that acts as a variable or a property that can be observed is just a specific usage of the EventProducer. As was already said, the event producer represents an abstract event generator. To create such event generator you can use the following designated initializer on EventProducer:

```swift
init(replayLength: Int, @noescape producer: (EventType -> ()) -> DisposableType?)
```

Parameter `replayLength` defines how many events should be replayed to each new observer. It represents the memory of the event producer. Event producers don't have to have memory so zero is a valid value for this parameter. Event producers without a memory are used to represent actions, something without a state, like button taps.

Parameter `producer` is a closure that actually generates events. The closure accepts a sink (another closure) through which it sends events and optionally returns a disposable that should be disposed when the created event producer is disposed. 

### About the Observation

An event producer (and so observable) can be observed by any number of observers. A new observer is registered with the already mentioned `observe` method. Here is its signature:

```swift
func observe(observer: EventType -> ()) -> DisposableType
```

We've already talked about the closure parameter `observer`, but it is also important to understand what the method returns. An observer stays registered until it’s unregistered or until the event producer is destroyed. To unregistered the observer manually we use a disposable object returned by the method `observe`. Think of it as a subscription that can be cancelled. To cancel it simply use the method `dispose`.

```swift
let subscription = captain.observe { name in … }

...

subscription.dispose()
```

### Transforming the Event Producers

The event producers are much more useful when they can be transformed and combined into another event producers. Bond comes with a number of methods that can transform an event producer into another event producer. Note that transforming an observable  does not create another observable, but the event producer that has not concept of 'current value'.

#### Map

```swift
func map<T>(transform: EventType -> T) -> EventProducer<T>
```

Creates an event producer that transforms each event from the receiver by the given transform closure.

#### Filter

```swift
func filter(includeEvent: EventType -> Bool) -> EventProducer<EventType>
```

Creates an event producer that forwards only events from the receiver that pass the given `includeEvent` closure. 

#### DeliverOn

```swift
func deliverOn(queue: Queue) -> EventProducer<EventType>
```

Creates an event producer that forwards events from the receiver to the given `Queue`.

#### Throttle

```swift
func throttle(seconds: Queue.TimeInterval, queue: Queue) -> EventProducer<EventType>
```

Creates an event producer that forwards no more than one event in the given number of seconds.

#### Skip

```swift
func skip(var count: Int) -> EventProducer<EventType>
```

Creates an event producer that ignores first count events from the receiver but forwards any subsequent.

#### StartWith

```swift
func startWith(event: EventType) -> EventProducer<EventType>
```

Creates an event producer that sends the given event and then continues by forwarding events from the receiver.

#### CombineLatestWith

```swift
func combineLatestWith<U: EventProducerType>(other: U) -> EventProducer<(EventType, U.EventType)>
```

Creates an event producer that combines the latest value of the receiver with the latest value from the given event producer. Will not generate an event until both event producers have generated at least one event.

#### SwitchToLatest

```swift
func switchToLatest() -> EventProducer<EventType.EventType>
```

Applicable only to the event producers whose events are also event producer. Creates an event producer that forwards events from the latest inner event producer.

#### Merge

```swift
func merge() -> EventProducer<EventType.EventType>
```

Applicable only to the event producers whose events are also event producer. Creates an event producer that forwards events from all received inner event producers.

#### IgnoreNil

```swift
func ignoreNil() -> EventProducer<EventType.SomeType>
```

Applicable only to the event producers whose events are optionals. Creates an event producer that forwards only events that are not nil values.

#### Distinct

```swift
func distinct() -> EventProducer<EventType>
```

Applicable only to the event producers whose events conform to the protocol `Equatable`. Creates an event producer that forwards only distinct events, i.e. no two equal events will be sent one after another.

### Bindings

Binding is a very simple concept. It's a way to propagate change. Change of a subject, like an observable, to an object, like a UI element or another observable. Let's say we need to update the observable that represents text of a label. Here is what we can do:

```swift
let captainName: Observable<String>
let nameLabelText: Observable<String>

captainName.observe { name in
  nameLabelText.next(name)
}
```

That will make the label text update whenever the captain changes. 

```swift
captainName.next(“Janeway”)
print(nameLabelText.value) // prints: Janeway
```

Bindings are at the core of Bond and there ought to be even simpler way to establish them. And, as you've seen it in the introduction, there is:

```swift
captainName.bindTo(nameLabelText)
```

Event producers and observables can be bound to any object that conforms to `BindableType` protocol. Event producers themselves conform to that protocol, but you can make any type conform to it.

Method `bindTo` returns a disposable that can cancel the binding. You usually don't need to worry about that because binding will be automatically canceled when either the event producer or observer are deallocated.

### UIKit and AppKit

UIKit and AppKit elements, of course, do not provide properties that are observable. UIKit and AppKit are also not KVO-compliant. Bond, therefore, provides its own extensions of the UIKit and AppKit elements in order to make bindings and property observations a piece of cake. For example, Bond provides its own variant of `text` property to the `UITextField` called `bnd_text`. It's an observable of `Observable<String?>` type that you can observe or make a binding to or from it.

```swift
let searchTextField = UITextField()

...

searchTextField.bnd_text.observeNew { text in
  print("Searching for \(text).")
  ...
}
```

To learn about available extensions just start typing `.bnd` on any UIKit or AppKit object or consult the [Extensions section](http://cocoadocs.org/docsets/Bond/4.0.0-alpha.2/Extensions.html) of the code reference. Extensions usually correspond to their respective UIKit or AppKit property names, just prefixed with `bnd_`, so it shouldn't be hard to find them.

#### NSObject

You rarely have to worry about disposing the observations, but when you do, Bond tries to be helpful. If you need to dispose an observation when your object (like view controller) is deallocated, you can use `bnd_bag` extension provided on NSObject (and thus on all its subclasses). It's a dispose bag, a collection of disposables, that will dispose all added disposables when your object is deallocated.

For example, if your view model outlives the view controller that uses it you must manually dispose any observation you've made. The simplest way to do that is to add the disposable returned by the `observe` method to the provided dispose bag:

```swift
class MyViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    viewModel.name
      .observe { name in
        print(name)
      }
      .disposeIn(bnd_bag)
  }
}
``` 

Note that it's not necessary to dispose bindings. When the binding target object is deallocated, the binding will be automatically disposed. That means that the following code is valid even if the view model outlives the view controller:

```swift
class MyViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel.name.bindTo(nameLabel.bnd_text)
  }
}
``` 


#### Notification Center

You can use Bond to observe notifications from NSNotificationCenter. To do that use the following extension:

```swift
extension NSNotificationCenter {
  public func bnd_notification(name: String, object: AnyObject?) -> EventProducer<NSNotification>
}
```

All you need to provide is a notification name you want to observe. Additionally, you can provide an object whose notifications you want to receive. Note that you should always manually dispose the observation when you no longer need it, preferably by putting the disposable in the dispose bag:

```swift
NSNotificationCenter.defaultCenter().bnd_notification("MyNotification", object: nil)
  .observe { notification in
    print("Received \(notification).")
  }
  .disposeIn(bnd_bag)
}
```

### Observable Array

When working with arrays, it's usually not enough to know only that the array has changed, but how exactly did it change. New elements could have been inserted into the array and old ones deleted or updated. Bond provides mechanisms for observing such fine-grained changes.

Creating an Observable with an array would enable observation of change of the array as whole, but to observe fine-grained changes you have to use `ObservableArray` type. Just like the Observable, it is a subclass of the `EventProducer` class, but instead of sending events that match the wrapped value type, it sends events of the `ObservableArrayEvent` type.  Such event contains both the new state of the array (array itself) and the operation that was just applied to the array (like element insertion or deletion). Operation is an enum type that describes the change.

Let's go through an example. Say that we need an array of names that we would like to observe. We would define it like this:

```swift
let names = ObservableArray(["Jim", "Spock"])
```

`ObservableArray` type mimics `Array` type so you can do same operations on it that you can do on the `Array` type. It also conforms to  `CollectionType` and `SequenceType` protocols.

Observation is done in the same way as the observation of the Observable or EventProducer. Main point to learn is that events it generates are of `ObservableArrayEvent` type. For example:

```swift
names.observe { event in
 print("Array is now: \(event.sequence)")
 
 switch event.operation {
 case .Insert(let elements, let fromIndex):
   print("Inserted \(elements) from index \(fromIndex)")
 case .Remove(let range):
   print("Removed elements in range \(range)")
 case .Update(let elements, let fromIndex):
   print("Updated \(elements) from index \(fromIndex)")
 case .Reset(let array):
   print("Array was reset to \(array)")
 case .Batch(let operations):
   print("Operations \(operations) were perform on the array")
 }
}
```

Our observer will then be called whenever an operation is applied to the array. It will also be called initially, at the time of the registration, with the last operation that was applied to the array. In our case that would be `.Reset` operation because it represents setting the array - something that the constructor does. Following will be printed:

```swift
$ Array is now: ["Jim", "Spock"]
$ Array was reset to ["Jim", "Spock"]
```

When we then change the array, our observer will be called. Appending new item

```swift
names.append("Scotty")
```

will result in

```swift
$ Array is now: ["Jim", "Spock", "Scotty"]
$ Inserted ["Scotty"] from index 2
```

Updating first element 

```swift
names[0] = "Uhura"
```

will then result in

```swift
$ Array is now: ["Uhura", "Spock", "Scotty"]
$ Updated ["Uhura"] from index 0
```

Removing first element afterwards

```swift
names.removeAtIndex(0)
```

will result in

```swift
$ Array is now: ["Spock", "Scotty"]
$ Removed elements in range 0..<1
```

Sometimes it is necessary to batch operations to the single event. It can be done like this:


```swift
names.performBatchUpdates { names in
  names.insert("Jim", atIndex: 0)
  names.removeLast()
}
```

will result in

```swift
$ Array is now: ["Jim", "Spock"]
$ Operations [.Insert(elements: ["Jim"], fromIndex: 0), .Remove(range: 2..<3)] were perform on the array.
```

#### UITableView and UICollectionView

Observable arrays can bound to UITableViews and UICollectionViews, leveraging that mechanisms of fine-grained change events. To bind them to those views, use following methods:

```swift
public func bindTo(tableView: UITableView, proxyDataSource: BNDTableViewProxyDataSource? = nil, createCell: (NSIndexPath, ObservableArray<ObservableArray<ElementType>>, UITableView) -> UITableViewCell) -> DisposableType {
public func bindTo(collectionView: UICollectionView, proxyDataSource: BNDCollectionViewProxyDataSource? = nil, createCell: (NSIndexPath, ObservableArray<ObservableArray<ElementType>>, UICollectionView) -> UICollectionViewCell) -> DisposableType {

```

Don't let the long method signature scare you. Methods accept three arguments: a table or collection view, optional proxy data source if you need to provide other data then the cells (like section names) and a `createCell` closure that will be used to create cells. Closure must accept three arguments that you use to create a cell and it must return a cell. Arguments it must accept are index path of the needed cell, a 2D observable array and a table or a collection view to dequeue cells from.

Such `bindTo` methods are provided only on two-dimensional observable arrays. The outer one represents sections and each inner one represents rows or items of the respective section. If your data is not arranged in sections so you have a one-dimension array, you can simply use `lift` method to wrap it into another array.

For example, let say we have two groups of names we would like to display in two sections of a table view:

```swift
let captains = ObservableArray(["Archer", "Kirk", "Picard"])
let firstOfficers = ObservableArray(["T'Pol", "Spock", "Riker"])
let dataSource = ObservableArray([captains, firstOfficers])
let tableView = UITableView()

dataSource.bindTo(tableView) { indexPath, dataSource, tableView in
  let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
  let name = dataSource[indexPath.section][indexPath.row]
  cell.textLabel.text = name
  return cell
}

```

If, on the other hand, we want to display only captains - a one-dimensional array - we could do this:

```swift
captains.lift().bindTo(tableView) { indexPath, dataSource, tableView in
  let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
  let name = dataSource[indexPath.section][indexPath.row]
  cell.textLabel.text = name
  return cell
}

```
 
### Key-Value-Observing

Using the Bond framework can simplify interaction with KVO properties. You can make an observable representation of them using the following constructor:

```swift
extension Observable {
  public convenience init(object: NSObject, keyPath: String)
}
```

You need to provide the `object` whose `keyPath` you want observed. Note that you also need to manually specialize the observable because Swift cannot infer the type of the property given only the key path.

```swift
let name = Observable<NSString?>(object: self.viewModel, keyPath: "name")
```

Be aware that the observable strongly references the given object. You never want to observe `self`!


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

