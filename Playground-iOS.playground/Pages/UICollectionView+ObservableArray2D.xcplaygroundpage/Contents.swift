//: [Previous](@previous)

import Foundation
import PlaygroundSupport
import UIKit
import Bond
import ReactiveKit

class Cell: UICollectionViewCell {

    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        contentView.backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = bounds
    }
}

class SectionHeader: UICollectionReusableView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .red
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let layout = UICollectionViewFlowLayout()
layout.minimumLineSpacing = 8
layout.minimumInteritemSpacing = 8
layout.sectionInset.top = 20
layout.sectionInset.bottom = 20

let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
collectionView.frame.size = CGSize(width: 300, height: 600)

collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")

// Note: Open the assistant editor to see the table view
PlaygroundPage.current.liveView = collectionView
PlaygroundPage.current.needsIndefiniteExecution = true

// Using custom binder to provide table view header titles
class CustomBinder<Changeset: SectionedDataSourceChangeset>: CollectionViewBinderDataSource<Changeset>, UICollectionViewDelegateFlowLayout where Changeset.Collection == Array2D<String, Int> {

    override var collectionView: UICollectionView? {
        didSet {
            collectionView?.delegate = self
        }
    }

    // Due to a bug in Swift related to generic subclases, we have to specify ObjC delegate method name
    // if it's different than Swift name (https://bugs.swift.org/browse/SR-2817).
    @objc (collectionView:viewForSupplementaryElementOfKind:atIndexPath:)
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! SectionHeader
            return headerView
        default:
            fatalError("Not implemented")
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 200, height: 20)
    }
}

// Array2D is generic over section metadata `Section` and item value `Item`.
// Section metadata is the data associated with the section, like section header titles.
// You can specialise `Section` to `Void` if there is no section metadata.
// Item values are values displayed by the table view cells.
let initialData = Array2D<String, Int>(sectionsWithItems: [
    ("A", [1, 2]),
    ("B", [10, 20])
    ])

let data = MutableObservableArray2D(initialData)


data.bind(to: collectionView, cellType: Cell.self, using: CustomBinder()) { (cell, item) in
    cell.titleLabel.text = "\(item)"
}

DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    data.appendItem(3, toSectionAt: 0)
}

DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    data.batchUpdate { (data) in
        data.appendItem(4, toSectionAt: 0)
        data.insert(section: "Aa", at: 1)
        data.appendItem(100, toSectionAt: 1)
        data.insert(item: 50, at: IndexPath(item: 0, section: 1))
    }
}

DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    data.moveItem(from: IndexPath(item: 0, section: 1), to: IndexPath(item: 0, section: 0))
}

//: [Next](@next)
