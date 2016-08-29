//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

import UIKit
import ReactiveKit

public extension UICollectionView {

  public var bnd_delegate: ProtocolProxy {
    return protocolProxy(for: UICollectionViewDelegate.self, setter: NSSelectorFromString("setDelegate:"))
  }

  public var bnd_dataSource: ProtocolProxy {
    return protocolProxy(for: UICollectionViewDataSource.self, setter: NSSelectorFromString("setDataSource:"))
  }
}

public extension SignalProtocol where Element: DataSourceEventProtocol, Error == NoError {

  @discardableResult
  public func bind(to collectionView: UICollectionView, createCell: @escaping (DataSource, IndexPath, UICollectionView) -> UICollectionViewCell) -> Disposable {

    let dataSource = Property<DataSource?>(nil)

    collectionView.bnd_dataSource.feed(
      property: dataSource,
      to: #selector(UICollectionViewDataSource.collectionView(_:cellForItemAt:)),
      map: { (dataSource: DataSource?, collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell in
        return createCell(dataSource!, indexPath as IndexPath, collectionView)
    })

    collectionView.bnd_dataSource.feed(
      property: dataSource,
      to: #selector(UICollectionViewDataSource.collectionView(_:numberOfItemsInSection:)),
      map: { (dataSource: DataSource?, _: UICollectionView, section: Int) -> Int in dataSource?.numberOfElements(inSection: section) ?? 0 }
    )

    collectionView.bnd_dataSource.feed(
      property: dataSource,
      to: #selector(UICollectionViewDataSource.numberOfSections(in:)),
      map: { (dataSource: DataSource?, _: UICollectionView) -> Int in dataSource?.numberOfSections() ?? 0 }
    )

    let serialDisposable = SerialDisposable(otherDisposable: nil)

    serialDisposable.otherDisposable = observeIn(ImmediateOnMainExecutionContext).observeNext { [weak collectionView] event in
      guard let collectionView = collectionView else {
        serialDisposable.dispose()
        return
      }

      dataSource.value = event.dataSource

      let applyEventOfKind: (DataSourceEventKind) -> () = { kind in
        switch kind {
        case .reload:
          collectionView.reloadData()
        case .insertRows(let indexPaths):
          collectionView.insertItems(at: indexPaths)
        case .deleteRows(let indexPaths):
          collectionView.deleteItems(at: indexPaths)
        case .reloadRows(let indexPaths):
          collectionView.reloadItems(at: indexPaths)
        case .moveRow(let indexPath, let newIndexPath):
          collectionView.moveItem(at: indexPath, to: newIndexPath)
        case .insertSections(let indexSet):
          collectionView.insertSections(indexSet)
        case .deleteSections(let indexSet):
          collectionView.deleteSections(indexSet)
        case .reloadSections(let indexSet):
          collectionView.reloadSections(indexSet)
        case .moveSection(let index, let newIndex):
          collectionView.moveSection(index, toSection: newIndex)
        case .beginUpdates:
          fatalError()
        case .endUpdates:
          fatalError()
        }
      }

      var bufferedEvents: [DataSourceEventKind]? = nil

      switch event.kind {
      case .reload:
        collectionView.reloadData()
      case .beginUpdates:
        bufferedEvents = []
      case .endUpdates:
        if let bufferedEvents = bufferedEvents {
          collectionView.performBatchUpdates({ bufferedEvents.forEach(applyEventOfKind) }, completion: nil)
        } else {
          fatalError("Bond: Unexpected event .endUpdates. Should have been preceded by a .beginUpdates event.")
        }
        bufferedEvents = nil
      default:
        if bufferedEvents != nil {
          bufferedEvents!.append(event.kind)
        } else {
          applyEventOfKind(event.kind)
        }
      }
    }
    
    return serialDisposable
  }
}
