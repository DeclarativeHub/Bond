# Protocol Proxies

Bond provides `NSObject` extensions that makes it easy to convert delegate method calls into signal.

Let us say that we need location update from `CLLocationManager` as a signal. We can leverage protocol proxies to provide us such signal.

First we need to create a delegate *protocol proxy* object. A suggestion is to make that in an extension of `ReactiveExtensions` where `Base` is the type we are extending - `CLLocationManager`:

```swift
extension ReactiveExtensions where Base: CLLocationManager {

    public var delegate: ProtocolProxy {
        return protocolProxy(for: CLLocationManagerDelegate.self, keyPath: \.delegate)
    }
}
```

We gave it the delegate type and a keypath where the delegate protocol proxy object should be set.  

Now we can convert a delegate method calls into signal. Let us do that for `locationManager(_:didUpdateLocations:)` method:

```swift
extension ReactiveExtensions where Base: CLLocationManager {

    ...

    public var locations: SafeSignal<[CLLocation]> {
        return delegate.signal(
            for: #selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)),
            dispatch: { (subject: SafePublishSubject<[CLLocation]>, locationManager: CLLocationManager, locations: [CLLocation]) in
                subject.next(locations)
            }
        )
    }
}
```

Method `signal(for:)` takes two parameters: a selector representing the method whose invocations should be intercepted and converted into signal events and a mapping closure that maps those invocations into signal events.

The closure's first argument must be a `SafePublishSubject` whose elements are of the same type as the elements of the signal we are providing, in our case `[CLLocation]`. Arguments that follow are the arguments of the method we are intercepting, `locationManager(_:didUpdateLocations:)`, which are in our case `CLLocationManager` and `[CLLocation]`. We must alway list all arguments there even if we are not using them all!

The closure will be executed each time `locationManager(_:didUpdateLocations:)` is called on `locationManager.delegate`. What is left is to fire an event on our signal when that happens. We do that be sending the event through the given subject.

With all that we can then use our `CLLocationManager` in a reactive fashion:

```swift
locationManager.reactive.locations.observeNext { locations in
  print("Did update locations \(locations).")
}.dispose(in: bag)
```

## Important: Delegate slot

Delegate protocol proxy object takes up the delegate slot so if you also need to implement other delegate methods manually, you **must not** set `locationManager.delegate = x`, rather set `locationManager.reactive.delegate.forwardTo = x`.

Doing that will forward invocations to methods not implemented by the protocol proxy to whatever object you have set there.

## Important: Argument types

Protocol proxies are implemented using ObjC runtime so there is one limitation when using them from Swift: Arguments of ObjC/C **enum** types are **not supported**.  

For example, method `UITableViewDataSource.tableView(_:commit:forRowAt:)` has the second argument of type `UITableViewCellEditingStyle` which is an ObjC enum that cannot be properly propagated to Swift throught protocol proxies.

To work around you should define that argument as `Int` and them initialize `UITableViewCellEditingStyle` manually from the raw value.


## Feeding data into the protocol proxy object

Protocol methods that return values are usually used to query data. Such methods can be set up to be fed from a property type. For example:

```swift
let numberOfItems = Property(12)

tableView.reactive.dataSource.feed(
  property: numberOfItems,
  to: #selector(UITableViewDataSource.tableView(_:numberOfRowsInSection:)),
  map: { (value: Int, _: UITableView, _: Int) -> Int in value }
)
```

Method `feed` takes three parameters: a property to feed from, a selector, and a mapping closure that maps from the property value and selector method arguments to the selector method return value.

You should not set more that one feed property per selector.
