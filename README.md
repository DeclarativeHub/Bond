# Bond, Swift Bond


Bond is a Swift binding framework that takes binding concept to a whole new level - boils it down to just one operator. It's simple, powerful, type-safe and multi-paradigm - just like Swift. 

Bond was created with two goals in mind: simple to use and simple to understand. One might argue whether the former implies the latter, but Bond will save you some thinking because both are true in this case. Its foundation are two simple classes - everything else are extensions and syntactic sugars.



## What can it do?


Say you'd like a label to reflect the state of a text field. Instead of going through all that 'action-target' pain, with Bond you'll do it like this:

```swift
	textField ->> label
```

That one line establishes a _bond_ between text field's text property and label's text property. In effect, whenever users makes a change to the text field, that change will be automatically propagated to the label.

More often than not, direct binding is not enough. Usually you need to transform input is some way, like prepending a greeting to a name. Of course, Bond has full confidence in functional paradigm. 

```swift
	textField.textDynamic().map { "Hi " + $0 } ->> label
```

Whenever a change occurs in the text field, new value will be transformed by the closure and propagated to the label.

In addition to `map`, another important functional construct is  `filter`. It's useful when we are interested only in some values of a domain. For example, when observing events of a button, we might be interested only in `TouchUpInside` event so we can perform certain action when user taps the button: 

```swift
	button.eventDynamic().filter { $0 == UIControlEvents.TouchUpInside } ->> { event in
      login()
    }
```

As you see, our binding target doesn't have to be an UI component, rather it can be an arbitrary action wrapped in a closure. We call that closure a `Listener` as it listens for changes of an object or a property that it's bonded to by `->>` operator.

Bond can also `reduce` multiple inputs into a single output. Following snippet depicts how values of two text fields can be reduced to a boolean value and applied to button's `disabled` property.

```swift
	reduce(emailField, passField) { email, pass  in
      return countElements(email) > 0 && countElements(pass) > 0
    } ->> loginButton
```

Whenever user types something into any of the text fields, expression will be evaluated and button state updated.
    
Bond's power is not, however, in coupling various UI components, but in a bonding of Model (or ViewModel) to View and vice-versa. It's great for MVVM paradigm. Here is how one could bond user's number of followers property of a model to a label. 

```swift
	numberOfFollowers.map { "\($0)" } ->> label
```

Point here is not in the simplicity of value assignment to text property of a label, but in the creation of a bond which automatically updates label text property whenever number of followers change.

Not impressed? Let me give you one last example. Say you have an array of repositories you would like to display in a table view. For each repository you have a name and its owner's profile photo. Of course, photo is not immediately available as it has to be downloaded, but once you get it, you want it to appear in table view's cell. Additionly, when user does 'pull down to refresh', and your array gets new repositiories, you want those in table view too. 

So how do you proceed? Well, instead of implementing a data source object, observing photo downloads with KVO and manually updating table view with new items, with Bond you can do all that in just few lines:

```swift
    repositories.map { [unowned self] (repository: Repository) -> RepositoryTableViewCell in
      let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as RepositoryTableViewCell
      repository.name ->> cell.nameLabel
      repository.photo ->> cell.avatarImageView
      return cell
    } ->> self.tableView
```

Yes, that's right!

(As always, when working with closures by extremely careful not to cause retain cycles! Note how we used `unowned self` in above example. If you are not familiar with concept of retain cycles, check out this: [Resolving Strong Reference Cycles for Closures](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html#//apple_ref/doc/uid/TP40014097-CH20-ID57))

(You can find demo app with additional examples [here](https://github.com/SwiftBond/Bond-Demo-App).)

## How does it work?

### Dynamic

Let's explore `numberOfFollowers` property from earlier example. What's its type? An `Int`? Well, kind of. Let's see how it is defined.

```swift
	let numberOfFollowers: Dynamic<Int>
```

So it is an `Int`, but an `Int` wrapped in a generic object of type `Dynamic`. That's the type you'll use to define a property or a variable whose changes you want to observe. Dynamic is the first of two classes that make up Bond framework.

How do you set its value? Just set it to the `value` property, like this:

```swift
	numberOfFollowers.value = 42
```

Dynamic is defined like this:

```swift
	public class Dynamic<T> {
		public var value: T
		public init(_ v: T)
	}
```

### Bond

We've already seen how to propagate change of value, but let's define it formally. Propagation of the change is done through a `Bond` established between a `Dynamic` and a `Listener` (a closure). Bond is the second of two classes that make up Bond framework. You create a bond by instantiating Bond object with a Listener and by bonding a Dynamic to it, like this:

```swift
	let myBond = Bond<Int>() { value in
		println("Number of followers changed to \(value).")
	}
	
	myBond.bind(numberOfFollowers)
```

Those few lines will establish a bond between the `numberOfFollowers` and the closure that prints each change. Bond lives as long as it is retained by someone else. Usually you'll create bonds as properties in you classes. `Bond` object retains bonded `Dynamic` object(s)!

Calling `bind` method is old-fashioned so it can be simplified by an already mentioned `->>` operator. Previous line can be rewritten like:

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
	  
	  public func bind(dynamic: Dynamic<T>, fire: Bool = true)
	  public func unbindAll()
	}
```

The parameter `fire` in `bind` method indicated whether listener should be called during binding process (with current value of the Dynamic) or not.

### What about UIKit

UIKit views and controls are not, of course, Dynamics and Bonds, so how can they act as agents in Bond word?

#### Dynamics

Controls and views for which it makes sense to are extended to provide Dynamics for commonly used properties, like UITextField's `text` property, UISlider's `value` property or UISwitch's `on` property.

To get a Dynamic representation of a property of UIKit object, call a method ending in `dynamic()`. For example, to get dynamic representation of UITextField's `text` property, call its `textDynamic()` method. Calling that method creates a Dynamic object that is coupled to the control or the view whose value it observes through mechanism like _action-target_ for controls or delegation for table views.

Each call to `*Dynamic()` method creates a new Dynamic object. **Returned object is not retained by the caller nor does it retains the caller.** In order to keep it alive, you have to either retain it or bind it to some Bond object (as mentioned previously - Bond retains bonded Dynamic).

Following table lists all available Dynamics of UIKit objects:

| Class        | Dynamic(s)     | Designated Dynamic |
|--------------|----------------|--------------------|
| UISlider     | valueDynamic() | valueDynamic()     |
| UIButton     | eventDynamic() | eventDynamic()     |
| UISwitch     | onDynamic()    | onDynamic()        |
| UITextField  | textDynamic()  | textDynamic()      |
| UIDatePicker | dateDynamic()  | dateDynamic()      |


You might be wondering what _Designated Dynamic_ is. It's way to access most commonly used Dynamic through method `designatedDynamic()`. Currently all UIKit objects have only one Dynamic property that is also a designed one. Having common name enables us to define protocol like 

```swift
	public protocol Dynamical {
	  typealias DynamicType
	  func designatedDynamic() -> Dynamic<DynamicType>
	}
```

and use that protocol to make binding easier. Instead of doing binding like

```swift
	titleTextField.textDynamic() ->> titleLabel
```

it allows us to do just

```swift
	titleTextField ->> titleLabel
```

because operator `->>` is overloaded to work with `Dynamicals`.

#### Bonds

Controls or views that present some data or have user-visible state, like UITextField's `text` property, UILabel's `text` property, UIImageView's `image` property or UIButton's `disabled` state property allow us to bind a Dynamic to them by providing a Bond object.

Provided Bond object is saved in `*Bond` property. Property holds a Bond that has a `Listener` implemented in a way that whenever a change is observed in any of bonded Dynamics, it updates control's or view's  property that it represents.

For example, UITextField provides `textBond` property that is coupled with its `text` property in a way that whenever a change is observed in any of bonded Dynamics, `text` is updated.

**Unlike Dynamics created from UIKit object, Bonds are retained by their view or control through Objective-C's associated objects mechanism.** Of course, Bond does not retain its parent.

Following table lists all available Bonds of UIKit objects:

| Class          | Bonds                                                   | Designated Bond |
|----------------|---------------------------------------------------------|-----------------|
| UIView         | alphaBond <br> hiddenBond <br> backgroundColorBond      | --              |
| UISlider       | valueBond                                               | valueBond       |
| UILabel        | textBond                                                | textBond        |
| UIProgressView | progressBond                                            | progressBond    |
| UIImageView    | imageBond                                               | imageBond       |
| UIButton       | enabledBond <br> titleBond <br> imageForNormalStateBond | enabledBond     |
| UISwitch       | onBond                                                  | onBond          |
| UITextField    | textBond                                                | textBond        |
| UIDatePicker   | dateBond                                                | dateBond        |
| UITableView    | dataSourceBond                                          | dataSourceBond  |


Like as for Dynamics, we can define protocol `Bondable`

```swift
	public protocol Bondable {
	  typealias BondType
	  var designatedBond: Bond<BondType> { get }
	} 
```

and use it to make binding easier. Instead of doing binding like

```swift
	titleTextField ->> titleLabel.textBond
```

it allows us to do just

```swift
	titleTextField ->> titleLabel
```

because operator `->>` is overloaded to work with `Bondables`.


### Functional concepts explained

Functions map, filter and reduce operate on Dynamic object(s) by creating a new Dynamic(s) that are bonded with source one(s). Newly created Dynamic(s) retain their source Dynamic(s)!

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

#### Composition

As each of these functions return another Dynamic, it is possible to compose (chain) more than one of them in order to get desired behaviour. For example, if we need to bind an Int property to a label (which provides a Bond of String type), but only if number is greater than 10, we could do it like this.

```swift
	number.filter { $0 > 10 }.map { "\($0)" } ->> label
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
	  public var insertListener: (([Int]) -> Void)?
	  public var removeListener: (([Int], [T]) -> Void)?
	  public var updateListener: (([Int]) -> Void)?
	  
	  override public init()
	  override public func bind(dynamic: Dynamic<Array<T>>, fire: Bool = false)
	}
```

Yeah, it's straightforward - it allows us to register different listeners for different events. Each listener is a closure that accepts an array of indices of objects that have been changed in bonded DynamicArray. Removal listener also receives objects that are removed. Listeners are always called after change has taken place.

Let's go through one example. We'll create a new bond to our `repositories` array, this time of ArrayBond type.

```swift
	let myBond = ArrayBond<Repository>()
	
	myBond.insertListener = { indices in
		println("Inserted objects at indices \(indices)")
	}
	
	myBond.updateListener = { indices in
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

DynamicArray supports per-element map and filter function. It does not support reduce at the moment.

Map function that operates on DynamicArray differs from map function that operates on basic Dynamic in a way that it evaluates values lazily. It means that at the moment of mapping, no element from source array is transformed to destination array. Elements are transformed on an as-needed basis. Thus the map function has O(1) complexity and no unnecessary table view cell will ever get created. (Beware that accessing `value` property of mapped DynamicArray returns whole array so it has to transform each element. Avoid accessing it.)

Because of its nature, filter function that operates on DynamicArray has O(n) complexity and you should be careful when using it. 

### Key-Value-Observing

There is one more neat thing about Bond. You can create a Dynamic that observers value chnages of some KVO-observable property. For example, you can bond a property of your existing Objective-C model object to a label with this simple one-liner:

```swift
	Dynamic.asObservableFor(self.user, keyPath: "numberOfFollowers") ->> label
```

## Installation

### Carthage

1. Add the following to your *Cartfile*:
  <br> `github "SwiftBond/Bond" ~> 2.0`
2. Run `carthage update`
3. Add the framework as described in [Carthage Readme](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)


### CocoaPods

1. Add the following to your *Podfile*:
  <br> `pod 'Bond', '~> 2.0'`
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

