# Bindings

Binding is a connection between a signal that produces events and a *bond* object that observers events and performs certain actions (e.g. updates UI).

The producing side of bindings are signals that are defined in ReactiveKit framework on top of which Bond is built. To learn more about signals, consult [ReactiveKit documentation](https://github.com/ReactiveKit/ReactiveKit).

The consuming side of bindings is represented by the `Bond` type. It is a simple struct that performs an action on a given target whenever the bound signal fires an event.

```swift
public struct Bond<Element>: BindableProtocol {
  public init<Target: Deallocatable>(target: Target, context: ExecutionContext, setter: @escaping (Target, Element) -> Void)
}
```

The only requirement is that the target must be *Deallocatable*, in other words that it provides a signal of its own deallocation.

```swift
public protocol Deallocatable: class {
  var deallocated: Signal<Void, NoError> { get }
}
```

All `NSObject` subclasses conform to that protocol out of the box. Let us see how we could implement a Bond for text property of a label. It is recommended to implement reactive extensions on `ReactiveExtensions` proxy protocol. That way you encapsulate extensions within the `.reactive` property.

```swift
extension ReactiveExtensions where Base: UILabel {

  var myTextBond: Bond<String?> {
    return bond { label, text in
      label.text = text
    }
  }
}
```

That's it! To bind any string signal, just use `bind(to:)` method on that bond.

```swift
let name: Signal<String, NoError> = ...
name.bind(to: nameLabel.reactive.myTextBond)
```

> Bonds will automatically ensure that the target object is updated on the main thread (queue). That means that the signal can generate events on a background thread without you worrying how the UI will be updated - it will always happen on the main thread.

Note that you can bind only __non-failable__ signals, i.e. signals with `NoError` error type. Only those kind of signals are safe to represent the data that UI displays.


Bindings will automatically dispose themselves (i.e. cancel source signals) when the binding target gets deallocated. For example, if we do

```swift
blurredImage().bind(to: imageView)
```

then the image processing will be automatically cancelled when the image view gets deallocated. Isn't that cool!

### Inline Bindings

Most of the time you should be able to replace an observation with a binding. Consider the following example. Say we have a signal of users

```swift
let presentUserProfile: Signal<User, NoError> = ...
```

and we would like to present a profile screen when a user is sent on the signal. Usually we would do something like:

```swift
presentUserProfile.observeOn(.main).observeNext { [weak self] user in
  let profileViewController = ProfileViewController(user: user)
  self?.present(profileViewController, animated: true)
}.dispose(in: bag)
```

But that's ugly! We have to dispatch everything to the main queue, be cautious not to create a retain cycle and ensure that the disposable we get from the observation is handled.

Thankfully Bond provides a better way. We can create inline binding instead of the observation. Just do the following

```swift
presentUserProfile.bind(to: self) { me, user in
  let profileViewController = ProfileViewController(user: user)
  me.present(profileViewController, animated: true)
}
```

and stop worrying about threading, retain cycles and disposing  because bindings take care of all that automatically. Just bind a signal to the target responsible for performing side effects (in our example, to the object responsible for presenting a profile view controller). The closure you provide will be called whenever the signal emits an event with both the target and the sent element as arguments.
