//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 DeclarativeHub/Bond
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

public protocol ObservableCollectionEventProtocol {

    associatedtype UnderlyingCollection: Collection

    var collection: UnderlyingCollection { get }
    var diff: [CollectionOperation<UnderlyingCollection.Index>] { get }
}

public struct ObservableCollectionEvent<UnderlyingCollection: Collection>: ObservableCollectionEventProtocol {

    /// The underlying collection managed by the observable collection.
    public let collection: UnderlyingCollection

    /// Description of changes made to the underlying collection.
    ///
    /// Delete, update and move from indices refer to the original collection.
    /// Insert and move to indices refer to the new collection (the one contained in this event).
    ///
    /// The diff structure is compatible with UICollectionView and UITableView batch updates requirements.
    /// NSTableView batch updates work with a sequence of operations called patch. Use `.diff.patch` to get
    /// the description of changes in the patch format.
    ///
    /// Changing `["A", "B"]` to `[]` gives the diff `[D(0), D(1)]`, while the patch might look like `[D(0), D(0)]`.
    ///
    /// - Note: Empty diff does not mean that the collection did not change, only that the diff is not available.
    /// On such event one should act as if the whole collection has changed - e.g. reload the table view.
    public let diff: [CollectionOperation<UnderlyingCollection.Index>]

    public init(collection: UnderlyingCollection, diff: [CollectionOperation<UnderlyingCollection.Index>]) {
        self.collection = collection
        self.diff = diff
    }
}
