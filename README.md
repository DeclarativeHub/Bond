# Bond, Swift Bond

[![Platform](https://img.shields.io/cocoapods/p/Bond.svg?style=flat)](http://cocoadocs.org/docsets/Bond/)
[![CI Status](https://travis-ci.org/ReactiveKit/Bond.svg?branch=master)](https://travis-ci.org/ReactiveKit/Bond)
[![Join Us on Gitter](https://img.shields.io/badge/GITTER-join%20chat-blue.svg)](https://gitter.im/ReactiveKit/General)
[![Twitter](https://img.shields.io/badge/twitter-@srdanrasic-red.svg?style=flat)](https://twitter.com/srdanrasic)

Bond is a Swift binding framework that takes binding concepts to a whole new level. It's simple, powerful, type-safe and multi-paradigm - just like Swift.

Bond is also a framework that bridges the gap between the reactive and imperative paradigms. You can use it as a standalone framework to simplify your state changes with bindings and reactive data sources, but you can also use it with ReactiveKit to complement your reactive data flows with bindings and reactive delegates and data sources.

Bond 5 in built on top of ReactiveKit framework. There is no special configuration, it just works!

**Note: This README describes Bond v5. For changes check out the [migration section](#migration)!**


## What can it do?

Let's say you would like to act on a text change event of a `UITextField`. Well, you could setup 'target-action' mechanism between your object and go through all that target-action selector registration pain, or you could simply use Bond and do this:

```swift
textField.bnd_text
  .observeNext { text in
    print(text)
  }
```

Now, instead of printing what the user has typed, you can _bind_ it to a `UILabel`:

```swift
textField.bnd_text
  .bind(to: label.bnd_text)
```

Because binding to a label text property is so common, you can even do:

```swift
textField.bnd_text
  .bind(to: label)
```

That one line establishes a binding between text field's text property and label's text property. In effect, whenever user makes a change to the text field, that change will be automatically propagated to the label.

More often than not, direct binding is not enough. Usually you need to transform input is some way, like prepending a greeting to a name. As Bond is backed by ReactiveKit it has full confidence in functional paradigm.

```swift
textField.bnd_text
  .map { "Hi " + $0 }
  .bind(to: label)
```

Whenever a change occurs in the text field, new value will be transformed by the closure and propagated to the label.

Notice how we've used `bnd_text` property of the UITextField. It's an observable representation of the `text` property provided by Bond framework. There are many other extensions like that one for various UIKit components. Just start typing _.bnd_ on any UIKit object and you'll get the list of available extensions.

For example, to observe button events do:

```swift
button.bnd_controlEvents(.touchUpInside)
  .observeNext { e in
    print("Button tapped.")
  }
```

Handling `touchUpInside` event is used so frequently that Bond comes with the extension just for that event:

```swift
button.bnd_tap
  .observe {
    print("Button tapped.")
  }  
```

You can use any ReactiveKit operator to transform or combine signals. Following snippet depicts how values of two text fields can be reduced to a boolean value and applied to button's enabled property.

```swift
combineLatest(emailField.bnd_text, passField.bnd_text) { email, pass in
    return email.length > 0 && pass.length > 0
  }
  .bind(to: button.bnd_enabled)
```

Whenever user types something into any of these text fields, expression will be evaluated and button state updated.

Bond's power is not, however, in coupling various UI components, but in the binding of a Model (or a ViewModel) to a View and vice-versa. It's great for MVVM paradigm. Here is how one could bind user's number of followers property of the model to the label.

```swift
viewModel.numberOfFollowers
  .map { "\($0)" }
  .bind(to: label)
```

Point here is not in the simplicity of a value assignment to the text property of a label, but in the creation of a binding which automatically updates label text property whenever number of followers change.

Bond also supports two way bindings. Here is an example of how you could keep username text field and username property of your view model in sync (whenever any of them change, other one will be updated too):

```swift
viewModel.username
  .bidirectionalBind(to: usernameTextField.bnd_text)
```

Bond is also great for observing various different events and asynchronous tasks. For example, you could observe a notification just like this:

```swift
NotificationCenter.default.bnd_notification("MyNotification")
  .observeNext { notification in
    print("Got \(notification)")
  }
  .disposeIn(bnd_bag)
```

Let me give you one last example. Say you have an array of repositories you would like to display in a collection view. For each repository you have a name and its owner's profile photo. Of course, photo is not immediately available as it has to be downloaded, but once you get it, you want it to appear in collection view's cell. Additionally, when user does 'pull down to refresh' and your array gets new repositories, you want those in collection view too.

So how do you proceed? Well, instead of implementing a data source object, observing photo downloads with KVO and manually updating the collection view with new items, with Bond you can do all that in just few lines:

```swift
repositories.bind(to: collectionView) { array, indexPath, collectionView in
  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! RepositoryCell
  let repository = array[indexPath.item]

  repository.name
    .bindTo(cell.nameLabel)
    .disposeIn(cell.onReuseBag)

  repository.photo
    .bindTo(cell.avatarImageView)
    .disposeIn(cell.onReuseBag)

  return cell
}
```

Yes, that's right!


## Observable

Observable wraps mutable state into an object that enables observation of that state. Whenever the state changes, an observer can be notified.

To create the observable, just initialize it with the initial value.

```swift
let name = Observable("Jim")
```

> `nil` is valid value for observables that wrap optional type.

Observables are signals just like signals of `Signal` type from ReactiveKit framework. To learn more about signals, consult [ReactiveKit documentation](https://github.com/ReactiveKit/ReactiveKit). Observables can be transformed into another signals, observed and bound in the same manner as signals can be.

For example, you can register an observer with `observe` or `observeNext` methods.

```swift
name.observeNext { value in
  print("Hi \(value)!")
}
```

> When you register an observer, it will be immediately invoked with the current value of the observable so that snippet will print "Hi Jim!".

To change value of the observable afterwards, just set the `value` property.

```swift
name.value = "Jim Kirk" // Prints: Hi Jim Kirk!
```

Observables, like signals, can be bound to views:

```swift
name.bind(to: nameLabel)
```

> Observable is just a typealias for ReactiveKit `Property` type. You can use that name if it suits you better.

## Bindings

Binding is a connection between a Signal/Observable that produces events and a Bond that observers events and performs certain action (e.g. updates UI).

The producing side of bindings are signals that are defined in ReactiveKit framework on top of which Bond is built. To learn more about signals, consult [ReactiveKit documentation](https://github.com/ReactiveKit/ReactiveKit).

The consuming side of bindings is represented by the `Bond` type. It's a simple struct that performs an action on a given target whenever the bound signal fires an event.

```swift
public struct Bond<Target: Deallocatable, Element>: BindableProtocol {
  public init(target: Target, setter: @escaping (Target, Element) -> Void)
}
```

The only requirement is that the target must be "deallocatable", in other words that it provides a Signal of its own deallocation.

```swift
public protocol Deallocatable: class {
  var bnd_deallocated: Signal<Void, NoError> { get }
}
```

All NSObject subclasses conform to that protocol out of the box. Let's see how we could implement a Bond for text property of a label.

```swift
extension UILabel {
  var myTextBond: Bond<UILabel, String?> {
    return Bond(target: self) { label, text in
      label.text = text
    }
  }
}
```

That's it! To bind any string signal, just use `bind(to:)` method on that bond.

```swift
let name: Signal<String, NoError> = ...
name.bind(to: nameLabel.myTextBond)
```

> Bonds will automatically ensure that the target object is updated on the main thread (queue). That means that the signal can generate events on a background thread without you worrying how the UI will be updated - it will always happen on the main thread.

Note that you can bind only __non-failable__ signals, i.e. signals with `NoError` error type. Only those kind of signals are safe to represent the data that UI displays.


Bindings will automatically dispose themselves (i.e. cancel source signals) when the binding target gets deallocated. For example, if we do

```swift
blurredImage().bind(to: imageView)
```

then the image processing will be automatically cancelled when the image view gets deallocated. Isn't that cool!

## Reactive Delegates

Bond provides NSObject extensions that makes it easy to convert delegate pattern into signals.

First make an extension on your type, UITableView in the following example, that provides a reactive delegate proxy:

```swift
extension UITableView {
  public var bnd_delegate: ProtocolProxy {
    return protocolProxy(for: UITableViewDelegate.self, setter: NSSelectorFromString("setDelegate:"))
  }
}
```

> Note: `bnd_delegate` is already provided by Bond. This is an example of the implementation.

You can then convert methods of that protocol into signals:

```swift
extension UITableView {
  var selectedRow: Signal<Int, NoError> {
    return bnd_delegate.signal(for: #selector(UITableViewDelegate.tableView(_:didSelectRowAtIndexPath:))) { (subject: PublishSubject<Int, NoError>, _: UITableView, indexPath: NSIndexPath) in 
      subject.next(indexPath.row)
    }
  }
}
```

Method `signal(for:)` takes two parameters: a selector to convert to a signal and a mapping closure that maps selector method arguments into a signal.

Now you can do:

```swift
tableView.selectedRow.observeNext { row in
  print("Tapped row at index \(row).")
}.disposeIn(bnd_bag)
```

**Note:** Protocol proxy takes up delegate slot of the object so if you also need to implement delegate methods manually, don't set `tableView.delegate = x`, rather set `tableView.bnd_delegate.forwardTo = x`.

Protocol methods that return values are usually used to query data. Such methods can be set up to be fed from a property type. For example:

```swift
let numberOfItems = Property(12)

tableView.bnd_dataSource.feed(
  property: numberOfItems,
  to: #selector(UITableViewDataSource.tableView(_:numberOfRowsInSection:)),
  map: { (value: Int, _: UITableView, _: Int) -> Int in value }
)
```

Method `feed` takes three parameters: a property to feed from, a selector, and a mapping closure that maps from the property value and selector method arguments to the selector method return value.

You should not set more that one feed property per selector.

Note that in the mapping closures of both `signal(for:)` and `feed` methods you must be explicit about argument and return types. Also, **you must use ObjC types as this is ObjC API**. For example, use `NSString` instead of `String`.


## Reactive Data Sources

Bond provides a way to make reactive data sources and allows such sources to be easily bound to table or collection views.

Any Signal that emits elements of the following type can be bound to a table or collection view

```swift
public struct DataSourceEvent<DataSource: DataSourceProtocol>: DataSourceEventProtocol {
  public let kind: DataSourceEventKind
  public let dataSource: DataSource
}
```

where the data source is any object conforming to `DataSource` protocol

```swift
public protocol DataSourceProtocol {
  func numberOfSections() -> Int
  func numberOfItems(inSection section: Int) -> Int
}
```

and kind is a case of the enumeration `DataSourceEventKind`:

```swift
public enum DataSourceEventKind {
  case reload

  case insertRows([IndexPath])
  case deleteRows([IndexPath])
  case reloadRows([IndexPath])
  case moveRow(IndexPath, IndexPath)

  case insertSections(IndexSet)
  case deleteSections(IndexSet)
  case reloadSections(IndexSet)
  case moveSection(Int, Int)

  case beginUpdates
  case endUpdates
}
```

If you have a signal that emits an array of elements, you can transform that signal into a signal that emits data source events using the operator `mapToDataSourceEvent` and bind it to a table view.

```swift
let places = Signal1.just(["London", "Berlin", "Copenhagen"])

places.mapToDataSourceEvent().bind(to: tableView) { places, indexPath, tableView in
  let cell = tableView.dequeueCell(withIdentifier: "Cell", for: indexPath) as! PlaceCell
  cell.place = places[indexPath.row]
  return cell
}
```

Whenever the signal emits new array, it will be mapped to a `.reload` event and cause the table view to update. To get fine-grained changes, you should use better data source.

### ObservableArray / MutableObservableArray

When working with arrays, it's usually not enough to know only that the array has changed, but how exactly did it change. New elements could have been inserted into the array and old ones deleted or updated. Bond provides mechanisms for observing such fine-grained changes.

Creating a Signal/Observable/Property of arrays enables observation of the change of the array as whole, but to observe fine-grained changes Bond provides you with the `ObservableArray` type. Just like the Observable, it is a type conforming to SignalProtocol, but instead of sending events that match the wrapped value type, it sends events of the `ObservableArrayChange` type that actually conforms to `DataSourceEventProtocol`. Such event contains both the array itself (the data source) and the change that was just applied to the array (like element insertion or deletion).

To create observable array, just initialize it with the initial array.

```swift
let names = MutableObservableArray(["Steve", "Tim"])
```

When observing observable array, events you receive will contain detailed description of changes that happened.

```swift
names.observeNext { e in
  print("array: \(e.source), change: \(e.change)")
}
```

You work with the observable array like you'd work with the array it encapsulates.

```swift
names.append("John") // prints: array ["Steve", "Tim", "John"], change: .inserts([2])
names.removeLast()   // prints: array ["Steve", "Tim"], change: .deletes([2])
names[1] = "Mark"    // prints: array ["Steve", "Mark"], change: .updates([1])
```

Observable array can be mapped or filtered. For example, if we map our array

```
names.map { $0.characters.count }.observeNext { event in
  print("array: \(e.source), change: \(e.change)")
}
```

then modifying it

```swift
names.append("Tony") // prints: array [5, 3, 4], change: .inserts([2])
```

gives us fine-grained notification of mapped array changes.

Mapping and filtering arrays operates on an array signal. To get the result back as an observable array, just bind it to an instance of ObservableArray.

```swift
let nameLengths = ObservableArray<Int>()
names.map { $0.characters.count }.bind(to: nameLengths) 
```

Such features enable us to build powerful UI bindings. Observable array can be bound to `UITableView` or `UICollectionView`. Just provide a closure that creates cells to the `bind(to:)` method.

```swift
let posts: ObservableArray <[Post]> = ...

posts.bind(to: tableView) { posts, indexPath, tableView in
  let cell = tableView.dequeueCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
  cell.post = posts[indexPath.row]
  return cell
}
```

Subsequent changes done to the `posts` array will then be automatically reflected in the table view.

#### Array diff

When you need to replace an array with another array, but need an event that contains fine-grained changes (for example to update table/collection view with nice animations), you can use method `replace(with:performDiff:)`. Let's say you have

```swift
let numbers: MutableObservableArray([1, 2, 3])
```

and you do

```swift
numbers.replace(with: [0, 1, 3, 4], performDiff: true)
```

then the row at index path 1 would be deleted and new rows would be inserted at index paths 0 and 3. The view would automatically animate only the changes from the *merge*. Helpful, isn't it.

### Observable2DArray / MutableObservable2DArray

Array is often not enough. Usually our data is grouped into sections. To enable such use case, Bond provides two-dimensional arrays that can be observed and bound to table or collection views.

Let's explain this type by example. First we'll need some sections. A section represents a group of items. Those items, i.e. section can have a metadata associated with it. In iOS it's useful to display section header and footer titles to the user so let's define that as our metadata:

```swift
typealias SectionMetadata = (header: String, footer: String)
```
> If you need only, for example, header title, then you don't need to define separate type. Just use `String` instead of `SectionMetadata` in examples that follow.

Now that we have defined our metadata type, we can create a section:

```swift
let cities = Observable2DArraySection<SectionMetadata, String>(
  metadata: (header: "Cities", footer: "That's it"),
  items: ["Paris", "Berlin"]
)
```

Section is defined with `Observable2DArraySection` type. It's generic over its metadata type and type of the items it can contain. To create a section we passed section metadata and section items.

We can now create an observable 2D array. Let's create mutable variant so we can later modify it.

```swift
let array = MutableObservable2DArray([cities])
```

You just pass it an array of sections. Such array can be bound to a table or collection view. You can bind it the same way as you would bind `ObservableArray`. However, if you want to display header and/or footer titles, you'll need to define `TableViewBond` object.

```swift
struct MyBond: TableViewBond {

  func cellForRow(at indexPath: IndexPath, tableView: UITableView, dataSource: Observable2DArray<SectionMetadata, String>) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    cell.textLabel?.text = array[indexPath]
    return cell
  }

  func titleForHeader(in section: Int, dataSource: Observable2DArray<SectionMetadata, String>) -> String? {
    return dataSource[section].metadata.header
  }

  func titleForFooter(in section: Int, dataSource: Observable2DArray<SectionMetadata, String>) -> String? {
    return dataSource[section].metadata.footer
  }
}
```

Only the method `cellForRow:at:tableView:` is required. Other two are optional and are used when we want to show header and/or footer titles.

Method `cellForRow:at:tableView:` describes how cells are instantiated (dequeued) and filled with data. Method `titleForHeader/Footer` just reads section metadata from the data source object and returns it.

> If you don't need to display header and/or footer titles, you don't need to create `TableViewBond` type. Just bind `Observable2DArray` as you would bind `ObservableArray` as described in the previous section of this document.

Now that we have a table view bond type, you can bind our array to the table view:

```swift
array.bind(to: tableView, using: MyBond())
```

We just pass it an instance of table view bond type.

And that's it. If you run that code you'll see a table view with one section that has header and footer and two items.

If you now modify the array like

```swift
array.appendItem("Copenhagen", toSection: 0)
```

the new item will automatically be inserted and animated into the table view.

You can also, for example; add another section:

```swift
let countries = Observable2DArraySection<SectionMetadata, String>(metadata: ("Countries", "No more..."), items: ["France", "Croatia"])
array.appendSection(countries)
```

There are many other methods. Just look at the code reference or source.

## Requirements

* iOS 8.0+ / macOS 10.9+ / tvOS 9.0+
* Xcode 8

## Communication

* If you'd like to ask a general question, use Stack Overflow.
* If you'd like to ask a quick question or chat about the project, try [Gitter](https://gitter.im/ReactiveKit/General).
* If you found a bug, open an issue.
* If you have a feature request, open an issue.
* If you want to contribute, submit a pull request (include unit tests).

## Installation

### Carthage

1. Add the following to your *Cartfile*:
  <br> `github "ReactiveKit/Bond" ~> 5.2`
2. Run `carthage update`
3. Add the framework as described in [Carthage Readme](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

### CocoaPods

1. Add the following to your *Podfile*:
  <br> `pod 'Bond', '~> 5.2'`
2. Run `pod install`.

## <a name="migration"></a>Migration

### Migration from v4.x to v5.0

There are some big changes in Bond v5! Bond is now backed by ReactiveKit framework. All reactive types have been moved down to ReactiveKit. Bond builds its infrastructure on top of ReactiveKit types, primarily on top of `Signal` that serves the purpose of `EventProducer`.

Bindings have been improved and simplified. It gives them better performances and additional uses. ObservableArray has been reimplemented and significantly simplified and optimised. New features are introduced: reactive delegates and reactive data sources.

What that means for you? Well, nothing has changed conceptually so your migration should be easy. Following is a list of changes:

* `EventProducer` is removed. Use Signal from ReactiveKit for reactive programming.
* Operator `deliverOn` is renamed to `observeOn`.
* Method `bindTo` is renamed to `bind(to:)`.
* Method `observe` is renamed to `observeNext`.
* `ObservableArray` is reimplemented. Mapping and filtering it is not supported any more.
* `ObservableArray` is now immutable. Use `MutableObservableArray` instead.
* Table view and collection view binding closure now has the data source as first argument and the index path as second argument.
* KVO can now be established using the method `dynamic(keyPath:ofType:)` on any NSObject subclass.
* `Queue` is removed. Use `DispatchQueue` instead.



## License

The MIT License (MIT)

Copyright (c) 2015-2016 Srdan Rasic (@srdanrasic)

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
