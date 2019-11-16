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

import Bond
import ReactiveKit
import RealmSwift

/*

// Get the default Realm
let realm = try! Realm()

// Convert realm results into a changeset signal
let puppies = realm.objects(Dog.self).toChangesetSignal()

// Changeset signals can then be bound to table or collection views
puppies.suppressError(logging: true).bind(to: tableView, cellType: UITableViewCell.self) { (cell, dog) in
    cell.textLabel?.text = dog.name
}

// Adding something to the results will cause the table view to insert the respective row
DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    try! realm.write {
        realm.add(myDog)
    }
}

*/

public extension RealmCollectionChange where CollectionType: Swift.Collection, CollectionType.Index == Int {

    public func toOrderedCollectionChangeset() throws -> OrderedCollectionChangeset<CollectionType> {
        switch self {
        case .initial(let collection):
            return OrderedCollectionChangeset(collection: collection, diff: OrderedCollectionDiff())
        case .update(let collection, let deletions, let insertions, let modifications):
            let diff = OrderedCollectionDiff(inserts: insertions, deletes: deletions, updates: modifications, moves: [])
            return OrderedCollectionChangeset(collection: collection, diff: diff)
        case .error(let error):
            throw error
        }
    }
}

public extension Results {

    public func toChangesetSignal() -> Signal<OrderedCollectionChangeset<Results<Element>>, NSError> {
        return Signal { observer in
            let token = self.observe { change in
                do {
                    observer.next(try change.toOrderedCollectionChangeset())
                } catch {
                    observer.failed(error as NSError)
                }
            }
            return BlockDisposable {
                token.invalidate()
            }
        }
    }
}

public extension Results: QueryableSectionedDataSourceProtocol {

    public var numberOfSections: Int {
        return 1
    }

    public func numberOfItems(inSection section: Int) -> Int {
        return count
    }

    public func item(at indexPath: IndexPath) -> Element {
        return self[indexPath.row]
    }
}
