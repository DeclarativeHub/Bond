# Data Source Signals


Bindings automatically populate the table or collection view with the data, perform partial of batched updates when needed, ensure proper thread and dispose themself when the view is deallocated.

Note that bindings will replace the existing collection or table view data source if such exists. Check out [custom data source in addition to bindings](#advanced-bindings-custom-binder-data-sources) for more info on that. 

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

### Advanced bindings (custom binder data sources)

A method that actually implements table view bindings is defined like this:

```swift
func bind(to tableView: UITableView, using binderDataSource: TableViewBinderDataSource<Element.Changeset>) -> Disposable
``` 

All binding methods presented in the previous use cases are just convenience methods that create and configure proper "binder data source" object. Binder data source is an object of `TableViewBinderDataSource ` type that manages the binding and implementes `UITableViewDataSource` protocol method.

If you need to customize the binding behaviour, you can subclass that type and then make a binding by passing your custom instance of `TableViewBinder` to `bind(to:using:)` method. You would do that if you need to further manage how events are applied to the table view - for example if you want different animations for different events or section headers and/or footers.

For example, if you need to support table view headers from a binding of `Array2D`, you can subclass the default binder data source and implement additional data source method:

```swift
// Using custom binder to provide table view header titles
class CustomBinder<Changeset: SectionedDataSourceChangeset>: TableViewBinderDataSource<Changeset> where Changeset.Collection == Array2D<String, Int> {

    // Important: Annotate UITableViewDataSource methods with `@objc` in the subclass, otherwise UIKit will not see your method!
    @objc func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return changeset?.collection[sectionAt: section]
    }
}
```

You can that use that binder in you binding code:

```swift
array2D.bind(to: tableView, cellType: UITableViewCell.self, using: CustomBinder()) { (cell, item) in
    cell.textLabel?.text = "\(item)"
}
```

In the same way you can subclass `CollectionViewBinderDataSource`.

**Note that due to the [limitations](https://stackoverflow.com/questions/48215689/dispatch-issue-with-generic-subclass-of-custom-table-view-controller) in Swift generic system, you have to provide ObjC names of the delegate methods if they differ from Swift names. For example**

```swift
@objc (collectionView:viewForSupplementaryElementOfKind:atIndexPath:)
func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    ...
}
```