_Notice: Bond v3 is out. Please read this document again if you're using older version._

# Bond, Swift Bond


Bond is a Swift binding framework that takes binding concept to a whole new level - boils it down to just one operator. It's simple, powerful, type-safe and multi-paradigm - just like Swift. 

Bond was created with two goals in mind: simple to use and simple to understand. One might argue whether the former implies the latter, but Bond will save you some thinking because both are true in this case. Its foundation are two simple classes - everything else are extensions and syntactic sugars.



## What can it do?


Say you'd like a label to reflect state of a text field. Instead of going through all the 'action-target' pain, with Bond you'll do it like this:

```swift
textField ->> label
```

That one line establishes a _bond_ between text field's text property and label's text property. In effect, whenever user makes a change to the text field, that change will be automatically propagated to the label.

More often than not, direct binding is not enough. Usually you need to transform input is some way, like prepending a greeting to a name. Of course, Bond has full confidence in functional paradigm. 

```swift
textField.dynText.map { "Hi " + $0 } ->> label
```

Whenever a change occurs in the text field, new value will be transformed by the closure and propagated to the label.

Notice how we've used `dynText` property of the UITextField. It's an observable representation of `text` property provided by Bond framework. There are many other properties like that one for various UIKit components.

In addition to `map`, another important functional construct is  `filter`. It's useful when we are interested only in some values of  domain. For example, when observing events of a button, we might be interested only in `TouchUpInside` event so we can perform certain action when user taps the button: 

```swift
lazy var loginButtonTapListener = Bond<UIControlEvents>() { event in
  // perform login
}

...

loginButton.dynEvent.filter(==, .TouchUpInside) ->> loginButtonTapListener
```

As you see, our binding target doesn't have to be an UI component, rather it can be an arbitrary action wrapped in a closure created by instantiating a `Bond` object. 

Closure is our `Listener`, while `Bond` is an object that manages bindings. We save actions in properties as we need to retain them.

Bond can also `reduce` multiple inputs into a single output. Following snippet depicts how values of two text fields can be reduced to a boolean value and applied to button's `enabled` property.

```swift
reduce(emailField.dynText, passField.dynText) { email, pass  in
  return countElements(email) > 0 && countElements(pass) > 0
} ->> loginButton.dynEnabled
```

Whenever user types something into any of the text fields, expression will be evaluated and button state updated.
    
Bond's power is not, however, in coupling various UI components, but in a bonding of Model (or ViewModel) to View and vice-versa. It's great for MVVM paradigm. Here is how one could bond user's number of followers property of a model to a label. 

```swift
viewModel.numberOfFollowers.map { "\($0)" } ->> label
```

Point here is not in the simplicity of value assignment to text property of a label, but in the creation of a bond which automatically updates label text property whenever number of followers change.

Bond also supports *two way* bindings. Here is an example of how you could keep username text field and username property of your view model in sync (whenever any of them change, other one will be updated to):

```swift
viewModel.username <->> usernameTextField.dynText
```

Notice the asymmetry of bi-directional bind operator. It's important which side of the expression something is on. In Bond, right side always retains left side! In this example, binding will exist as long as `usernameTextField` lives.

Not impressed? Let me give you one last example. Say you have an array of repositories you would like to display in a table view. For each repository you have a name and its owner's profile photo. Of course, photo is not immediately available as it has to be downloaded, but once you get it, you want it to appear in table view's cell. Additionly, when user does 'pull down to refresh', and your array gets new repositiories, you want those in table view too. 

So how do you proceed? Well, instead of implementing a data source object, observing photo downloads with KVO and manually updating table view with new items, with Bond you can do all that in just few lines:

```swift
var tableViewDataSourceBond: UITableViewDataSourceBond<UITableViewCell>!

override func viewDidLoad() {
  super.viewDidLoad()

  // create a data source bond for table view
  tableViewDataSourceBond = UITableViewDataSourceBond(tableView: self.tableView)

  // map repositories to cells and bind
  repositories.map { [unowned self] (repository: Repository) -> RepositoryTableViewCell in
    let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as RepositoryTableViewCell
    repository.name ->> cell.nameLabel
    repository.photo ->> cell.avatarImageView
    return cell
  } ->> tableViewDataSourceBond
}
```

Yes, that's right!

(As always, when working with closures by extremely careful not to cause retain cycles! Note how we used `unowned self` in above example. If you are not familiar with concept of retain cycles, check out this: [Resolving Strong Reference Cycles for Closures](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html#//apple_ref/doc/uid/TP40014097-CH20-ID57))

(You can find demo app with additional examples [here](https://github.com/SwiftBond/Bond-Demo-App).)

## How does it work?

Bond is in essence a variation of the [Observer pattern](http://en.wikipedia.org/wiki/Observer_pattern). There is a subject of type `Dynamic<T>` and a listener (observer) of type `T -> Void` (closure). Dynamic holds a value of some type `T` and calls bound listeners whenever new value is set.

In addition to basic Observer pattern, Bond leverages additional object to make bindings lifecycle simple. It's type is `Bond<T>`. It wraps listener closure and can bind itself to Dynamics of same generic type `T`. The simplicity lies in that the bindings exist as long as corresponding Bond object exists. There is no need to manually unregister listeners.

Let's dive deeper.

### Dynamic

Consider `numberOfFollowers` property from earlier example. What's its type? An `Int`? Well, kind of. Let's see how it is defined.

```swift
let numberOfFollowers: Dynamic<Int>
```

So it is an `Int`, but an `Int` wrapped in a generic object of type `Dynamic<T>`. That's the type you'll use to define a property or a variable whose changes you want to observe. Dynamic is the first of two classes that make up Bond framework.

How do you set its value? Just set it to the `value` property, like this:

```swift
numberOfFollowers.value = 42
```

Dynamic is defined like this:

```swift
public class Dynamic<T> {
  public init(_ v: T)
  public func bindTo(bond: Bond<T>)
  
  public var value: T
  public let valueBond: Bond<T>
}
```

### Bond

We've already seen how to propagate change of value, but let's define it formally. Propagation of the change is done through a `Bond` established between a `Dynamic` and a `Listener` (a closure). Bond is the second of two classes that make up Bond framework. You create a bond by instantiating Bond object with a Listener and by binding a Dynamic to it, like this:

```swift
let myBond = Bond<Int>() { value in
  println("Number of followers changed to \(value).")
}

numberOfFollowers.bindTo(myBond)
```

Those few lines will establish a bond between the `numberOfFollowers` and the closure that prints each change. Bond lives as long as it is retained by someone else. Usually you'll create bonds as properties in your classes. `Bond` object retains bonded `Dynamic` object(s)!

Calling `bindTo` method is old-fashioned so it can be simplified by an already mentioned `->>` operator. Previous line can be rewritten like:

```swift
numberOfFollowers ->> myBond
```

Very simple indeed. Dynamic on the left side, Bond on the right side.

Bond is defined like this:

```swift
public class Bond<T> {
  public typealias Listener = T -> Void
  public var listener: Listener?
  
  public init()
  public init(_ listener: Listener)
  
  public func bind(dynamic: Dynamic<T>)
  public func unbindAll()
}
```

#### Dynamic as Bond

Dynamic can also act as a Bond because it has a Bond attached to itself that updates its value. You can access that bond through `valueBond` property. What that means is that you can bind one Dynamic to another.

```swift
// given that both 'usernames' are of type Dynamic<String>
viewmodel.username ->> self.username
```

#### The cycle of doom

Be very careful not to make binding cycles like this:

```swift
d1 ->> d2
d2 ->> d1
```

Or even more subtile:

```swift
d1 ->> d2
d2 ->> d3
d3 ->> d1
```

While they'll work, they'll cause retain cycles and will stay in memory until your app is killed.

You can fix first example by using *two way binding* operator

```swift
d1 <->> d2
```

You should probably never be in situation that you need something as in second example, but should you be, you can fix it by making feedback binding weak. You cannot use operator for that, but it can be achieved like this:

```swift
d1 ->> d2
d2 ->> d3
d3.bindTo(d1.valueBond, fire: false, strongly: false)
```


### What about UIKit

UIKit views and controls are not, of course, Dynamics and Bonds, so how can they act as agents in Bond word?

Controls and views for which it makes sense to are extended to provide Dynamics for commonly used properties, like UITextField's `text` property, UISlider's `value` property or UISwitch's `on` property.

To get a Dynamic representation of a property of UIKit object, use the variant that has `dyn*` prefix. For example, to get dynamic representation of UITextField's `text` property, use `dynText` property. Returned Dynamic object is coupled to the control or the view whose value it observes and updates through mechanism like _Action-Target_ or _Key-Value-Observing_.

Following table lists all available Dynamics of UIKit objects:

| Class          | Dynamic(s)                                              | Designated Dynamic |
|----------------|---------------------------------------------------------|-----------------|
| UIView         | dynAlpha <br> dynHidden <br> dynBackgroundColor         | --              |
| UISlider       | dynValue                                                | dynValue        |
| UILabel        | dynText <br> dynAttributedText                          | dynText         |
| UIProgressView | dynProgress                                             | dynProgress     |
| UIImageView    | dynImage                                                | dynImage        |
| UIButton       | dynEnabled <br> dynTitle <br> dynImageForNormalState    | dynEnabled      |
| UIBarItem      | dynEnabled <br> dynTitle <br> dynImage                  | dynEnabled      |
| UISwitch       | dynOn                                                   | dynOn           |
| UITextField    | dynText                                                 | dynText         |
| UITextView     | dynText <br> dynAttributedText                          | dynText         |
| UIDatePicker   | dynDate                                                 | dynDate         |
| UIActivityIndicatorView | dynIsAnimating                                 | dynIsAnimating  |

You might be wondering what _Designated Dynamic_ is. It's way to access most commonly used Dynamic through property `designatedDynamic`. Having common name enables us to define protocol like 

```swift
public protocol Dynamical {
  typealias DynamicType
  var designatedDynamic: Dynamic<DynamicType> { get }
}
```

and use that protocol to make binding easier. Instead of doing binding like

```swift
titleTextField.dynText ->> titleLabel
```

it allows us to do just

```swift
titleTextField ->> titleLabel
```

because operator `->>` is overloaded to work with `Dynamical`.


### Functional concepts explained

Functions map, filter, reduce, zip, rewrite and skip operate on Dynamic object by creating a new Dynamic that is bonded with source one. Newly created Dynamic retain their source Dynamic!

#### Map

```swift
func map<T, U>(dynamic: Dynamic<T>, f: T -> U) -> Dynamic<U>
```

Map function maps a Dynamic to a new Dynamic of different type. Value transformation from source type to destination type is performed by a given closure. Newly created Dynamic internally holds a Bond to source Dynamic that's updating its value whenever value of source Dynamic changes. It applies given transformation closure on each update.

Map is also available as a method of Dynamic class with first parameter omitted (which is assumed to be `self`). 

#### Filter

```swift
func filter<T>(dynamic: Dynamic<T>, f: T -> Bool) -> Dynamic<T> 
```

Filter function creates a new Dynamic that's bonded to its source Dynamic in similar way as it is done with map function. Difference is that there are no type transformations, but the filtering of source values. Newly created Dynamic changes its value only when new value of source Dynamic satisfies expression in a given closure.

Filter is also available as a method of Dynamic class with first parameter omitted (which is assumed to be `self`). 

#### Reduce

```swift
reduce<A, B, T>(dA: Dynamic<A>, dB: Dynamic<B>, f: (A, B) -> T) -> Dynamic<T>  
reduce<A, B, C, T>(dA: Dynamic<A>, dB: Dynamic<B>, dC: Dynamic<C>, f: (A, B, C) -> T) -> Dynamic<T>
```

Reduce is a simple function that takes two or more Dynamics and returns a new Dynamic of arbitrary type. New Dynamic holds a Bond to each of source Dynamics and updates its value whenever any of source Dynamics change. It updates its value by applying a given closure to values of source Dynamics.

#### Zip

```swift
zip<T, U>(dynamic: Dynamic<T>, value: U) -> Dynamic<(T, U)>
zip<T, U>(d1: Dynamic<T>, d2: Dynamic<U>) -> Dynamic<(T, U)>
```

First variant of zip takes a Dynamic and a value and produces new Dynamic with those two in a tuple. Produced Dynamic fires whenever source Dynamic fires. _Note that if you pass an object as a value, it'll be retained by the produced Dynamic!_

Second variant of zip takes two Dynamics and produces new Dynamic with those two in a tuple. Produced Dynamic fires whenever any of source Dynamics fire.

#### Rewrite

```swift
rewrite<T, U>(dynamic: Dynamic<T>, value: U) -> Dynamic<U>
```

When you don't care about a value of a Dynamic but are still interested in change events, you can create a Dynamic that rewrites value of source Dynamic with some constant. _Note that if you pass an object as a value, it'll be retained by the produced Dynamic!_

#### Skip

```swift
skip<T>(dynamic: Dynamic<T>, count: Int) -> Dynamic<T>
```

You can use skip to create a Dynamic that'll not dispatch change events for `count` times. 

#### Any

```swift
any<T>(dynamics: [Dynamic<T>]) -> Dynamic<T>
```

Any expects an array of one or more Dynamics of same type and produces a Dynamic that'll fire whenever any of source Dynamics fire.

#### Composition

As each of these functions return another Dynamic, it is possible to compose (chain) more than one of them in order to get desired behaviour. For example, if we need to bind an Int property to a label (which provides a Bond of String type), but only if number is greater than 10, we could do it like this.

```swift
number.filter { $0 > 10 }.map { "\($0)" } ->> label
```

### The three operators

#### Bind and fire

```swift
d ->> b
```

```swift
d1 ->> d2
```

Establishes binding between a Dynamic and a Bond or another Dynamics's `valueBond`. Calls Listener closure right after binding. Equivalent to:

```swift
d.bindTo(b, fire: true, strongly: true)
```

```swift
d1.bindTo(d2.valueBond, fire: true, strongly: true)
```

#### Bind only

```swift
d ->| b
d1 ->| d2
```

Establishes binding between a Dynamic and a Bond or another Dynamics's `valueBond`. Does not call Listener closure after binding. Equivalent to:

```swift
d.bindTo(b, fire: false, strongly: true)
```

```swift
d1.bindTo(d2.valueBond, fire: false, strongly: true)
```

#### Bi-directional bind 

```swift
d1 <->> d2
```

Establishes two way binding between two Dynamics. Equivalent to:

```swift
d1.bindTo(d2.valueBond, fire: true, strongly: true)
d2.bindTo(d1.valueBond, fire: false, strongly: false)
```

### Arrays are special (and great)

Remember that famous table view example from earlier? Let's see how that repositories array is defined.

```swift
let repositories: DynamicArray<Repository>
```

As you can see, arrays are special kind of Dynamics. Reason behind that is that we are usually not interested in change of the array object as whole, rather we are interested in changes that occurred within the array like insertions, deletions or updates.

DynamicArray is a subclass of the Dynamic class with additional methods for array manipulation. It is designed to resemble standard Swift array. It implements same manipulation methods, subscript syntax and a support for `for-in` iteration. It's defined like this:

```swift
public class DynamicArray<T>: Dynamic<Array<T>>, SequenceType {
  public override init(_ v: Array<T>)
  
  public var count: Int 
  public var capacity: Int
  public var isEmpty: Bool 
  public var first: T?
  public var last: T?
  
  public func append(newElement: T)
  public func append(array: Array<T>)
  public func removeLast() -> T 
  public func insert(newElement: T, atIndex i: Int)
  public func splice(array: Array<T>, atIndex i: Int)
  public func removeAtIndex(index: Int) -> T
  public func removeAll(keepCapacity: Bool)
  public subscript(index: Int) -> T
}
```

As the DynamicArray is the subclass of the Dynamic, it can be bonded with any Bond of same generic type, but that's not what we usually want. Basic Bond object allows us to observe only value changes, and value is in this case an array as whole. In order to observe fine-grain changes, we need a special kind of Bond. It's called `ArrayBond` and it's defined in following way:

```swift
public class ArrayBond<T>: Bond<Array<T>> {
  public var willInsertListener: ((DynamicArray<T>, [Int]) -> Void)?
  public var didInsertListener: ((DynamicArray<T>, [Int]) -> Void)?

  public var willRemoveListener: ((DynamicArray<T>, [Int]) -> Void)?
  public var didRemoveListener: ((DynamicArray<T>, [Int]) -> Void)?

  public var willUpdateListener: ((DynamicArray<T>, [Int]) -> Void)?
  public var didUpdateListener: ((DynamicArray<T>, [Int]) -> Void)?
  
  override public init()
  override public func bind(dynamic: Dynamic<Array<T>>)
}
```

Yeah, it's straightforward - it allows us to register different listeners for different events. Each listener is a closure that accepts DynamicArray itself and an array of indices of objects that will be or have been changed.

Let's go through one example. We'll create a new bond to our `repositories` array, this time of ArrayBond type.

```swift
let myBond = ArrayBond<Repository>()
	
myBond.didInsertListener = { array, indices in
	println("Inserted objects at indices \(indices)")
}
	
myBond.didUpdateListener = { array, indices in
	println("Updated objects at indices \(indices)")
}
	
repositories ->> myBond
	
repositories.insert(Repository(...), atIndex: 0)
// prints: Inserted objects at indices [0]
	
repositories[4] = Repository(...)
// prints: Updated objects at indices [4]
```

Nice!

#### Map and Filter

DynamicArray supports per-element map and filter function. It does not support other functions at the moment.

Map and filter functions that operate on DynamicArray differ from functions that operate on basic Dynamic in a way that they evaluate values lazily. It means that at the moment of mapping or filtering, no element from source array is transformed to destination array. Elements are transformed on an as-needed basis. Thus the map function has O(1) complexity and no unnecessary table view cell will ever get created. Filter function has O(n) complexity. (Beware that accessing `value` property of mapped or filtered DynamicArray returns empty array.)


#### UITableView

You can use dynamic array to feed a UITableView. To do this, first create a bond of type `UITableViewDataSourceBond`. You'll need to pass a table view during initialization.

```swift
var tableViewDataSourceBond: UITableViewDataSourceBond<UITableViewCell>!

override func viewDidLoad() {
  super.viewDidLoad()

  // create a data source bond for table view
  tableViewDataSourceBond = UITableViewDataSourceBond(tableView: self.tableView)
  
  ...
}
```

`UITableViewDataSourceBond` will register itself as a `dataSource` for table view so you should not change table view's data source or it'll break binding! Next, you need to bind an array of type DynamicArray<UITableViewCell> to that bond. You can do that by doing map on your data source array, like this:

```swift
  // map repositories to cells and bind
  repositories.map { [unowned self] (repository: Repository) -> UITableViewCell in
    let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as RepositoryTableViewCell
    repository.name ->> cell.nameLabel
    repository.photo ->> cell.avatarImageView
    return cell
  } ->> tableViewDataSourceBond
```

`UITableViewDataSourceBond` implements following methods of `UITableViewDataSource` protocol:

```swift
numberOfSectionsInTableView:
tableView:numberOfRowsInSection:
tableView:cellForRowAtIndexPath:
```

If you need to provide other information to the table view, you can have your class adhere to protocol `UITableViewDataSource` and implement methods you need. After that, set `nextDataSource` property of UITableViewDataSourceBond to your object.

#### Multiple sections

If your table view needs to display more than one section, you can feed it with a DynamicArray of DynamicArrays of UITableViewCells. Don't run away, it's actually as simple as:


```swift
  let sectionOfApples = apples.map { [unowned self] (apple: Apple) -> UITableViewCell in
    let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as AppleTableViewCell
    cell.nameLabel = apple.name
    return cell
  }
  
  let sectionOfPears = pears.map { [unowned self] (pear: Pear) -> UITableViewCell in
    let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as PearTableViewCell
    cell.nameLabel = pear.name
    return cell
  }
  
  DynamicArray([sectionOfApples, sectionOfPears]) ->> tableViewDataSourceBond
```

#### UICollectionView

Just as you can bind dynamic arrays to table views, you can bind them to collection views. Steps are same identical, just with different types: map your dynamic array to a dynamic array of `UICollectionViewCell` objects and bind it to a bond of type `UICollectionViewDataSourceBond`. Here is an example:

```swift
var collectionViewDataSourceBond: UICollectionViewDataSourceBond<UICollectionViewCell>!

override func viewDidLoad() {
  super.viewDidLoad()

  // create a data source bond for collection view
  collectionViewDataSourceBond = UICollectionViewDataSourceBond(collectionView: self.collectionView)
  
    // map repositories to cells and bind
  repositories.map { [unowned self] (repository: Repository, index: Int) -> UICollectionViewCell in
    let indexPath = NSIndexPath(forItem: index, inSection: 0)
    let cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as RepositoryCollectionViewCell
    repository.name ->> cell.nameLabel
    repository.photo ->> cell.avatarImageView
    return cell
  } ->> collectionViewDataSourceBond
}
```

Notice how we've used variant of `map` that provides both an object to map and its index in the array. We need that index in order to build index path. Collection view differs from table view in that the index path is required when dequeueing cell. 

It's also possible to bind multiple sections by placing individual section dynamic arrays into another dynamic array, just like it's done for table views.

```swift
  DynamicArray([sectionOfApples, sectionOfPears]) ->> collectionViewDataSourceBond
```

### Key-Value-Observing

You can create a Dynamic that observers value changes of some KVO-observable property. For example, you can bind a property of your existing Objective-C model object to a label with this simple one-liner:

```swift
dynamicObservableFor(self.user, keyPath: "name", defaultValue: "") ->> nameLabel
```

Default value is used when observed property is set to `nil`. Dynamic returned by this method will only observe changes the property. Setting its `value` will have no effect on bound property. If you need two way binding, keep reading.

#### Two way Key-Value-Observing

To create bi-directional Dynamic representation a KVO property, use the following variant of the method:

```swift
dynamicObservableFor<T>(object: NSObject, #keyPath: String, #from: AnyObject? -> T, #to: T -> AnyObject?) -> Dynamic<T> 
```

Difference is that instead of the default value you need to provide transformations *from* and *to* observed type. KVO is not type-safe so you can't see actually type, rather you see `AnyObject?`. 

For example, if KVO property is of NSString type and you want its `Dynamic<String>` representation, you can do following:

```swift
let name: Dynamic<String> = dynamicObservableFor(self.user, keyPath: "name", from: { ($0 as? String) ?? "" }, to: { $0 })
```

`from` closure optionally downcasts passed value to String. That will succeed if passed value is of NSString type. It will fail if it is of some other type or if it is `nil`. `to` closure converts value to NSString. Swift can do that implicitly, so you can just pass the object.

After you get a Dynamic, you can easily bind it to, for example, UITextField.

```swift
name <->> nameTextField
```

For some other types, you might need to do something like this:

```swift
let height: Dynamic<Float> = dynamicObservableFor(self.user, keyPath: "height", from: { ($0 as NSNumber).floatValue }, to: { NSNumber(float: $0) })
```


### NSNotificationCenter

You can create a Dynamic that observers notifications posted by NSNotificationCenter. During initialization you need to provide notification name and a closure that'll parse notification into Dynamic's type. If you are interested only in notifications from specific object, pass that object too. 

```swift
let orientation: Dynamic<UIDeviceOrientation> = dynamicObservableFor(UIDeviceOrientationDidChangeNotification, object: nil) {
  notification -> UIDeviceOrientation in
  return UIDevice.currentDevice().orientation
}
```


## Installation

### Carthage

1. Add the following to your *Cartfile*:
  <br> `github "SwiftBond/Bond" ~> 3.0`
2. Run `carthage update`
3. Add the framework as described in [Carthage Readme](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)


### CocoaPods

1. Add the following to your *Podfile*:
  <br> `pod 'Bond', '~> 3.0'`
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


## Roadmap

Bond has yet to be shipped in an app. It was tested with many examples, but if there is a bug, please don't yell. Open an Issue, fix it yourself and make a pull request or contact me on Twitter (@srdanrasic) or by email (srdan.rasic@gmail.com). Should you have any suggestion or a critique, do the same.


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

