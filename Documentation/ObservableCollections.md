# Observable Colections

## ObservableArray / MutableObservableArray

When working with arrays, usually it is not enough to know that the array has changed. We need to know how exactly did it change. New elements could have been inserted into the array and old ones deleted or updated. Bond provides mechanisms for observing such fine-grained changes.

Creating a Signal/Observable/Property of an array enables observation of the change of the array as whole, but to observe fine-grained changes Bond provides you with the `ObservableArray` type. Just like the Property, it is a type that implements `SignalProtocol`, but instead of sending events that match the wrapped value type, it sends events of the `ObservableArrayChange` type. That type conforms to `DataSourceEventProtocol` so observable arrays can be [bound to a collection or table view](DataSourceSignals.md).

To create an observable array, just initialize it with a normal array.

```swift
let names = MutableObservableArray(["Steve", "Tim"])
```

We can then observe the observable array. Events we will receive contain detailed description of the changes that happened.

```swift
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

Observable array can be mapped or filtered. For example, if we map our array

```
names.map { $0.characters.count }.observeNext { e in
  print("array: \(e.source), change: \(e.change)")
}
```

then modifying it

```swift
names.append("Tony") // prints: array [5, 3, 4], change: .inserts([2])
```

gives us fine-grained notification of mapped array changes.

Mapping and filtering arrays operates on an array signal. If you need to get the result back as an observable array, you can bind it to an instance of `MutableObservableArray`.

```swift
let nameLengths = MutableObservableArray<Int>()
names.map { $0.characters.count }.bind(to: nameLengths)
```

Such features enable us to build powerful UI bindings. Observable arrays can be bound to table or collection views. Just provide a closure that creates cells to the `bind(to:)` method.

```swift
let todoItems: ObservableArray<TodoItem> = ...

todoItems.bind(to: collectionView, cellType: TodoItemCell.self) { (cell, todoItem) in
    cell.titleLabel.text = todoItem.name
}
```

Subsequent changes done to `todoItems` array will then be automatically reflected in the table view. Check out [data source signals](DataSourceSignals.md) for detailed documentation on such bindings.

### ObservableArray diff

When you need to replace an array with another array, but need an event that contains fine-grained changes (for example to update table/collection view with nice animations), you can use method `replace(with:performDiff:)`. Let's say you have

```swift
let numbers: MutableObservableArray([1, 2, 3])
```

and you do

```swift
numbers.replace(with: [0, 1, 3, 4], performDiff: true)
```

then the row at index path 1 would be deleted and new rows would be inserted at index paths 0 and 3. The view would automatically animate only the changes from the *merge*. Helpful, isn't it.

### Array signal diff

If you have a signal whose element is an array and elements of that array are hashable, you can apply `diff` operator on that signal.  

```swift
// Given
let todoItems: SafeSignal<[TodoItem]> = ...

// ...we can apply the diff operator and bind it to a table or collection view
todoItems
    .diff()
    .bind(to: tableView) { ... }
```

When `todoItems` signal emits a new array, the `diff` operator will run the diff algorithm against the previously emitted array and emit only fine-grained changes that will then update the table or collection view appropriately.

## Observable2DArray / MutableObservable2DArray

Array is often not enough. Usually our data is grouped into sections. To enable such use case, Bond provides two-dimensional arrays that can be observed and bound to table or collection views.

Let us explain them with an example. First we will need some sections. A section represents a group of items. Those items, i.e. a section, can have some metadata associated with them. In iOS it is useful to display section header and footer titles to the user so let us define that as our metadata:

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

Section is defined with `Observable2DArraySection` type. It is generic over its metadata type and type of the items it contains. To create a section we passed section metadata and initial section items.

We can now create an observable 2D array. Let us create a mutable variant so that we can later modify it.

```swift
let array = MutableObservable2DArray([cities])
```

You just pass it an array of sections. Such array can then be bound to a table or collection view. You can bind it the same way as you would bind `ObservableArray`. 

We can modify the array like

```swift
array.appendItem("Copenhagen", toSection: 0)
```

the new item would automatically be inserted and animated into the table view.

We can also, for example, add another section:

```swift
let countries = Observable2DArraySection<SectionMetadata, String>(metadata: ("Countries", "No more..."), items: ["France", "Croatia"])
array.appendSection(countries)
```

### Observable2DArray and table view section headers or footers

To display table view section headers or footers from `Observable2DArray` one could leverage [protocol proxies](ProtocolProxies.md) in the following way:

```swift
tableView.reactive.dataSource.signal(
    for: #selector(UITableViewDataSource.tableView(_:titleForHeaderInSection:)),
    dispatch: { (subject: SafePublishSubject<Void>, tableView: UITableView, section: Int) -> String? in
        return array.sections[section].metadata.header
    }
).bind(to: tableView) { _ in } // binding starts the signal
```
