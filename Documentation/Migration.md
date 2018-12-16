# Bond 7

Bond 7 is all about observable collections! They are now much more powerful, it is easy to customize binders and create your own variants of observable collections. Anything that conforms to `Swift.Collection` can now be made observable. Bond now also supports observable trees! Check out [observable collections documentation](ObservableCollections.md) and new playgrounds in the project workspace.

Bond 7 updates only observable collections APIs. All other APIs remain unchanged. APIs for use cases like creating, mutating and binding collections remain mostly unchanged, however there are breaking changes in the collection/table view binders and the observable collection event type. Make sure to check out playgrounds in the project workspace to learn about the new stuff.

### Observable Collections

In previous versions of Bond, each observable collection provided its own event type. For example, events of `ObservableArray` were of the type `ObservableArrayEvent`, events of `Observable2DArray` were of type `Observable2DArrayEvent` and so on. Those events represented the respective observable collection changes as "diff".

Bond 7 consolidates all change events under a single protocol `ChangesetProtocol`. 

```swift
/// A type that represents a collection change description, i.e. a modification of a collection.
public protocol ChangesetProtocol {

    associatedtype Diff
    associatedtype Operation
    associatedtype Collection

    /// A description of the change represented by this changeset as a diff.
    var diff: Diff { get }

    /// A description of the change represented by this changeset as a patch.
    /// Patch is a sequence of operations applied to the collection in order.
    var patch: [Operation] { get }

    /// Collection in its final state.
    var collection: Collection { get }
}
```

A changeset provides the collection itself as well as the description of the change in both "diff" and "patch" variant. 

Diff is a description of changes where indices of deletions, updates and moves from refer to the original collection (before the change), while insertion and move to indices refer to the final collection. Diff does not imply the order of the operations. `UICollectionView` and `UITableView` can use diff to perform batch updates. 

Another way to describe changes is called patch. Patch represents a sequence of operations like insert, delete, update or move that if applied to the original collection, one after another, will produce final collection. On macOS, `NSTableView` can use patch to perform batch updates.

You can use changeset type to get both kinds of change descriptions. 

Bond 7 provides few implementations of the changeset protocol:

  * `OrderedCollectionChangeset<Collection: Swift.Collection>` for ordered collections like arrays, 2D arrays, lists and other collection where order of elements matters. 
  * `UnorderedCollectionChangeset<Collection: Swift.Collection>` for unordered collections like dictionary, set and other collection where order of elements does not matter. 
  * `TreeChangeset<Collection: TreeNodeProtocol>` for trees.

The implementations mostly differ in how they specialize the associated `Diff` and (patch) `Operation` types. In ordered collections, position of elements matter, so moving elements within the collection makes sense. Thus the ordered collection diff is defined as:

```swift
public struct OrderedCollectionDiff<Index>: OrderedCollectionDiffProtocol {

    /// Indices of inserted elements in the final collection index space.
    public var inserts: [Index]

    /// Indices of deleted elements in the source collection index space.
    public var deletes: [Index]

    /// Indices of updated elements in the source collection index space.
    public var updates: [Index]

    /// Indices of moved elements where `from` is an index in the source collection
    /// index space, while `to` is an index in the final collection index space.
    public var moves: [(from: Index, to: Index)]
}
```

While unordered collection diff is missing the move operations because those make no sense in unordered collections like dictionary or set. 

```swift
public struct UnorderedCollectionDiff<Index>: UnorderedCollectionDiffProtocol {

    /// Indices of inserted elements in the final collection index space.
    public var inserts: [Index]

    /// Indices of deleted elements in the source collection index space.
    public var deletes: [Index]

    /// Indices of updated elements in the source collection index space.
    public var updates: [Index]
}
```

Abstracting collection change in such fashion simplifies observable collections. Since the changeset contains the collection itself it has all needed state and we can define (mutable) observable collection as a property of such changeset:

```swift
public typealias MutableObservableArray<Element> = Property<OrderedCollectionChangeset<[Element]>>
```

Methods like append, insert or remove are then implemented as extensions on the `Property` type.

Other collections follow the same principle. This also makes it super easy to define you own observable collections. For example, if you have your own collection type `MySuperArray` that conforms to `Swift.Collection` protocol, you can make the observable variant just by doing:

```swift
public typealias MySuperObservableArray<Element> = Property<OrderedCollectionChangeset<MySuperArray<Element>>>
``` 

You can then bind it to the collection or table view without any additional code!

### Data Sources

In previous versions of Bond, observable collections implemented `DataSourceProtocol` which enabled them to be bound to collection or table views. That principle is followed in Bond 7, although changes were made to make it work with the new changeset concept. `DataSourceProtocol` that is used for `UITableView` and `UICollectionView` bindings has been renamed to `SectionedDataSourceProtocol` because we now also have `FlatDataSourceProtocol` that is used for `NSTableView` on macOS.

`OrderedCollectionChangeset` as well as `Swift.Array` now conform to `SectionedDataSourceChangesetConvertible` which works in combination with `SectionedDataSourceProtocol` to make signals or properties of those types bindable to collection or table views.

You can now also bind observable dictionaries or sets to table or collection views by applying `sortedCollection()` operator on them to convert them into an ordered collection.

### Custom Binder Data Sources

Bond 7 makes it easier to provide custom binder data sources. Check out [custom data sources documentation](DataSourceSignals.md#advanced-bindings-custom-binder-data-sources).