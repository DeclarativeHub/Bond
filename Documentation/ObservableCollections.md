# Observable Colections

## ObservableArray / MutableObservableArray

When working with arrays, usually it is not enough to know that the array has changed. We need to know how exactly did it change. New elements could have been inserted into the array and old ones deleted or updated. Bond provides mechanisms for observing such fine-grained changes.

Creating a `Signal` or `Property` of an array type enables observation of the change of the array as whole, but to observe fine-grained changes, Bond provides you with the `ObservableArray` type. It's actually a `Property` that sends events of the `Changeset` type that describes fine-grained changes. Such property can be [bound to a collection or table view](DataSourceSignals.md).

To create an observable array, just initialize it with a normal array.

```swift
let names = MutableObservableArray(["Steve", "Tim"])
```

We can then observe the observable array. Events we will receive contain detailed description of the changes that happened.

```swift
names.observeNext { e in
    print("array: \(e.collection), diff: \(e.diff), patch: \(e.patch)")
}
```

You work with the observable array like you would work with the array it encapsulates.

```swift
names.append("John") // prints: array: ["Steve", "Tim", "John"], diff: Inserts: [2], patch: [I(John, at: 2)]
names.removeLast()   // prints: array: ["Steve", "Tim"], diff: Deletes: [2], patch: [D(at: 2)]
names[1] = "Mark"    // prints: array: ["Steve", "Mark"], diff: Updates: [1], patch: [U(at: 1, newElement: Mark)]
```

Observable array can be mapped (`mapCollection`), filtered (`filterCollection`) or sorted (`sortedCollection`). For example, if we map our array

```
names.mapCollection { $0.count }.observeNext { e in
    print("array: \(e.collection), diff: \(e.diff), patch: \(e.patch)")
}
```

then modifying it

```swift
names.append("Tony") // prints: array: [5, 4, 4], diff: Inserts: [2], patch: [I(4, at: 2)]
```

gives us fine-grained notification of mapped collection changes.

If you need to get the result back as an observable array, you can bind it to an instance of `MutableObservableArray`.

```swift
let nameLengths = MutableObservableArray<Int>()
names.mapCollection { $0.count }.bind(to: nameLengths)
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

Let us explain them with an example. First we will need some sections. A section represents a group of items. Those items, i.e. a section, can have some metadata associated with them. In iOS it is useful to display section header or footer titles to the user so let us define our section metadata as `String`. We will also use `String` for items.

```swift
let array2D = MutableObservableArray2D(Array2D<String, String>(sectionsWithItems: [
    ("Cities", ["Paris", "Berlin"])
]))
```

Array2D is generic over its section type and type of the items it contains. To create a 2D array we passed section metadata and initial section items. We then wrapped everything into a `MutableObservableArray2D` so that we can observe changes.

Such array can be bound to a table or collection view. You can bind it the same way as you would bind `ObservableArray`. 

We can modify the array like

```swift
array2D.appendItem("Copenhagen", toSectionAt: 0)
```

the new item would automatically be inserted and animated into the table view.

We can also, for example, add another section

```swift
array2D.appendSection("Contries")
```

and then an item into that section:

```swift
array2D.appendItem("France", toSectionAt: 1)
```

### Observable2DArray and table view section headers or footers

To display table view section headers or footers from `Observable2DArray` you can override the table view binder.  Check out `UITableView+ObservableArray2D` playground page in the project to learn how to do that.

## ObservableDictionary, ObservableSet, ObservableTree, ObservableCollection

There are many more observable collections provided by Bond. It's also easy to create your own observable collections. Anything that conforms to `Swift.Collection` can be used in an observable fashion. Check out `Observable Collections` playground page in the project workspace.
