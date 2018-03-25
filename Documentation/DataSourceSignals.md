# Data Source Signals

## Definitions

Signals that emit elements of `DataSourceEventProtocol` type are called *data source signals*. Elements emitted by such signals are called *data source events*. 

Data source events are defined by the following protocol:

```swift
public protocol DataSourceEventProtocol {

    associatedtype DataSource: DataSourceProtocol

    /// The data source itself.
    var dataSource: DataSource { get }
    
    /// Represents data source event kind like insertion, deletion, etc.
    var kind: DataSourceEventKind { get }
}
```

As you can see, each event contains the data source object itself and a property that indicates what kind of an event happend.

Data source is defined by the protocol

```swift
public protocol DataSourceProtocol {
  func numberOfSections() -> Int
  func numberOfItems(inSection section: Int) -> Int
}
```

while event kind is an enum that represent a modification of the data source

```swift
public enum DataSourceEventKind {
    case reload

    case insertItems([IndexPath])
    case deleteItems([IndexPath])
    case reloadItems([IndexPath])
    case moveItem(IndexPath, IndexPath)

    case insertSections(IndexSet)
    case deleteSections(IndexSet)
    case reloadSections(IndexSet)
    case moveSection(Int, Int)

    case beginUpdates
    case endUpdates
}
```

Examples of signals whose elements conform to `DataSourceEventProtocol` out of the box are:

```swift
SafeSignal<[T]>
SafeSignal<ObservableArrayEvent<T>>
SafeSignal<Observable2DArrayEvent<S, T>>
```

Observable arrays are also signals whose elements conform to `DataSourceEventProtocol` so we should include them too:

```swift
MutableObservableArray<T>
MutableObservable2DArray<S, T>
ObservableArray<T>
Observable2DArray<S, T>
```

Such signals can be bound to a collection or table view using bindings that save you from implementing data source objects.

## Collection and Table View Bindings

Bindings automatically populate the table or collection view with the data, perform partial of batched updates when needed, ensure proper thread and dispose themself when the view is deallocated.

Note that bindings will replace the existing collection or table view data source if such exists. Check out [custom data source in addition to bindings](#Custom-data-source-in-addition-to-bindings) for more info on that. 

### Collection view of single cell type

The simplest binding is a binding of a one-dimensional collection like an array or an observable array to a collection or table view with one section where all cells are of the same type.

Assuming that we have

```swift
// a signal that emits elements of `DataSourceEventProtocol` type
let todoItems: SafeSignal<[TodoItem]> = ...

// a collection view
let collectionView: UICollectionView = ...

// and a collection view cell
class TodoItemCell: UICollectionViewCell { ... }
```

we can then establish a binding using the `bind(to:cellType:)` method:

```swift
todoItems.bind(to: collectionView, cellType: TodoItemCell.self) { (cell, todoItem) in
    cell.titleLabel.text = todoItem.name
}
```

We give it the collection view instance, type of the cells we are going to display our data in and a closure that will configure cells. Each time signal emits new data source event, the binding will update the collection view and use the provided closure to configure the cell with the data source element at the respective index path.

The binding will automatically register the cell type with the collection view, using type name as a reuse identifier, so you don't have to register it manually.

### Table view of single cell type

Establishing a table view binding follows the same pattern as the collection view binding:

```swift
let todoItems: SafeSignal<[TodoItem]> = ....
let tableView: UITableView = ...
class TodoItemCell: UITableView Cell { ... }
 
...
 
todoItems.bind(to: tableView, cellType: TodoItemCell.self) { (cell, item) in
    cell.titleLabel.text = item.name
}
```

### Animations of partials updates in table view

When the signal emits a data source event indicating partial update like row insertion or row move, the update will be animated using `UITableViewRowAnimation.automatic` by default. You can change that by setting the `rowAnimation` parameter:

```swift
todoItems.bind(to: tableView, cellType: TodoItemCell.self, rowAnimation: .fade) { (cell, item) in
    cell.titleLabel.text = item.name
}
```

To completely disable animations, do:

```swift
todoItems.bind(to: tableView, cellType: TodoItemCell.self, animated: false) { (cell, item) in
    cell.titleLabel.text = item.name
}
```

### Animations of partials updates in collection view

`UICollectionView` animations are managed by `UICollectionViewLayout` so you will need to subclass it and implement custom animations there.

### Multiple cell types in a collection or table view

When the data is going to be displayed by cells of more than one type, you can use method `bind(to:createCell:)` that allows you to dequeue cells manually.

```swift
todoItems.bind(to: collectionView) { (todoItems, indexPath, collectionView) in
    let item = todoItems[indexPath.row]
    if item.isCompleted {
        let cell = collectionView.dequeueReusableCell(withIdentifier: "CompletedTodoItemCell", for: indexPath) as! CompletedTodoItemCell
        // configure cell with item
        return cell
    } else {
        let cell = collectionView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath) as! TodoItemCell
        // configure cell with item
        return cell
    }
}
```

You are given the data source object itself, the respective index path and the collection view. Based on that you will have to dequeue, configure and return the cell. Don't forget to register the cells and their reuse identifiers with the collection view.

There is an equivalent `bind(to:createCell:)` method for table views.

### Bindings within the table or collecton view bindings

Bindings within the table or collection view bindings **must be manually disposed**. For example, if we have a button in the cell that should complete the todo task when tapped, we could flat map button taps into the operation that completes the todo task and then bind that operation signal to the cell itself. Cells, however, get reused as user scrolls the table or collection view so we have to put the binding disposable into the bag and dispose that bag each time the cell is reused.

```swift
todoItems.bind(to: collectionView, cellType: TodoItemCell.self) { (cell, todoItem) in
    cell.titleLabel.text = todoItem.name
    
    // Dispose the cell's bag to dispose any previous bindings made to the cell
    cell.reactive.bag.dispose()
    
    cell.completeTodoItemButton.reactive.tap
        .flatMapLatest { todoService.complete(todoItem) }
        .bind(to: cell) { cell in 
            print("Completed task \(todoItem)")
            cell.style = .done
        }
        .dispose(in: cell.reactive.bag) // Put the disposable into the bag
}
```

If we do not dispose the inner bindings manually, each time the cell would be reused, it would just establish a new binding alongside the previous ones so tapping the button would complete all tasks that have ever been displayed that cell.

### Advanced bindings for table views

A method that actually implements table view bindings is defined like this:

```swift
func bind(to tableView: UITableView, using binder: TableViewBinder<DataSource>) -> Disposable
``` 

All binding methods presented in the previous use cases are just convenience methods that create and configure proper "binder" object. Binder is an object of `TableViewBinder` type that manages the binding.

If you need to customize the binding behaviour, you can subclass that type and then make a binding by passing your custom instance of `TableViewBinder` to `bind(to:using:)` method. You would do that if you need to further manage how an event is applied to the table view - for example if you want different animations for different events.

Check out [the implementation of the default binder](https://github.com/DeclarativeHub/Bond/blob/master/Sources/Bond/UIKit/UITableView.swift#L62) to learn what would make sense to subclass and override.

### Custom data source in addition to bindings

When a binding is established, Bond will install its own data source object to the collection or table view. You can access that object by accessing `tableView.reactive.dataSource`, i.e. `collectionView.reactive.dataSource` property. Bond implements its data source object as a [protocol proxy](ProtocolProxies.md) which means that any unimplemented methods can be forwarded to another data source object.

Bond will automatically set an existing table/collection view data source object as `forwardTo` on its own data source - if such exists at the time of binding. You can also set custom data source that should receive unimplemented method calls manually by setting `*.reactive.dataSource.forwardTo`.

For example, if you want to provide table view section headers - something that cannot be done through bindings, you would implement you custom data source object:

```swift
class MyDataSource /* or: extension MyViewController */: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fatalError("This will never be called.")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("This will never be called.")
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Title"
    }
}
```

You would then set that object as `forwardTo` on reactive data source:

```swift
tableView.reactive.forwardTo = myDataSource
```

Make sure you do **not** set this as `tableView.dataSource` **after** the binding is established - that would break the binding! If you do that **before** the binding is established, that's fine. In fact, Bond will then automatically "move" it to `forwardTo`.

Note how we implemented the two required methods with `fatalError`. In order to compile the code, those two have to be implemented, but they will never be called because they are also implemented by Bond's own reactive data source.

### Custom data source method implementations in addition to bindings

Since `*.reactive.dataSource` is a protocol proxy object, we can provide implementations for certain data source methods without having to implement custom data source object like in the previous example.

For example, if the table view supports reordering, we would like to get relevant index paths when the user moves rows. Instead of implementing a custom data source object with the method `tableView(_:moveRowAt:to:)`, we can convert calls to that method into a signal by leveraging protocol proxies:

```swift
let didMoveRow = tableView.reactive.dataSource.signal(
    for: #selector(UITableViewDataSource.tableView(_:moveRowAt:to:)),
    dispatch: { (subject: SafePublishSubject<(IndexPath, IndexPath)>, tableView: UITableView, source: IndexPath, destination: IndexPath) -> Void in
        subject.next((source, destination))
    }
)
```

What we get is a signal that emits elements when user reorders the table view:

```swift
didMoveRow.observeNext { (source, destination) in
    print("did move row at \(source) to \(destination)")
}
```

Bond implements `collectionView.reactive.selectedItemIndexPath` and `tableView.reactive.selectedRowIndexPath` in the safe fashion.

A similar solution could be used to provide table view section header and footer titles. To learn more about protocol proxies or their restrictions check out [their documentation](ProtocolProxies.md).

