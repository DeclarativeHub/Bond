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

#if os(iOS)

import UIKit
import ReactiveKit

extension SignalProtocol where Element: SectionedDataSourceChangesetConvertible, Error == Never {

    /// Binds the signal of data source elements to the given picker view.
    ///
    /// - parameters:
    ///     - pickerView: A picker view that should display the data from the data source.
    ///     - createTitle: A closure that configures the title for a given picker view row with the given data source at the given index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the picker view is deallocated.
    @discardableResult
    public func bind(to pickerView: UIPickerView, createTitle: @escaping (Element.Changeset.Collection, Int, Int, UIPickerView) -> String?) -> Disposable {
        let binder = PickerViewBinderDataSource<Element.Changeset>(createTitle)

        return bind(to: pickerView, using: binder)
    }

    /// Binds the signal of data source elements to the given table view.
    ///
    /// - parameters:
    ///     - pickerView: A picker view that should display the data from the data source.
    ///     - binder: A `PickerViewBinderDataSource` or its subclass that will manage the binding.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the picker view is deallocated.
    @discardableResult
    public func bind(to pickerView: UIPickerView, using binderDataSource: PickerViewBinderDataSource<Element.Changeset>) -> Disposable {
        binderDataSource.pickerView = pickerView
        return bind(to: pickerView) { (_, changeset) in
            binderDataSource.changeset = changeset.asSectionedDataSourceChangeset
        }
    }
}

extension SignalProtocol where Element: SectionedDataSourceChangesetConvertible, Element.Changeset.Collection: QueryableSectionedDataSourceProtocol, Error == Never {

    /// Binds the signal of data source elements to the given picker view.
    ///
    /// - parameters:
    ///     - pickerView: A picker view that should display the data from the data source.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the picker view is deallocated.
    @discardableResult
    public func bind(to pickerView: UIPickerView) -> Disposable {
        let createTitle: (Element.Changeset.Collection, Int, Int, UIPickerView) -> String? = { (dataSource, row, component, pickerView) in
            let indexPath = IndexPath(row: row, section: component)
            let item = dataSource.item(at: indexPath)

            return String(describing: item)
        }

        return bind(to: pickerView, using: PickerViewBinderDataSource<Element.Changeset>(createTitle))
    }
}

private var PickerViewBinderDataSourceAssociationKey = "PickerViewBinderDataSource"

public class PickerViewBinderDataSource<Changeset: SectionedDataSourceChangeset>: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {

    public var createTitle: ((Changeset.Collection, Int, Int, UIPickerView) -> String?)?

    public var changeset: Changeset? = nil {
        didSet {
            pickerView?.reloadAllComponents()
        }
    }

    open weak var pickerView: UIPickerView? = nil {
        didSet {
            guard let pickerView = pickerView else { return }
            associateWithPickerView(pickerView)
        }
    }

    public override init() {
        self.createTitle = nil
    }

    /// - parameter createTitle: A closure that configures the title for a given picker view row with the given data source at the given index path.
    public init(_ createTitle: @escaping (Changeset.Collection, Int, Int, UIPickerView) -> String?) {
        self.createTitle = createTitle
    }

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return changeset?.collection.numberOfSections ?? 0
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return changeset?.collection.numberOfItems(inSection: component) ?? 0
    }

    open func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let changeset = changeset else { fatalError() }
        if let createTitle = createTitle {
            return createTitle(changeset.collection, row, component, pickerView)
        } else {
            fatalError("Subclass of PickerViewBinderDataSource should override and implement pickerView(_:titleForRow:forComponent) method if they do not initialize `createTitle` closure.")
        }
    }

    private func associateWithPickerView(_ pickerView: UIPickerView) {
        objc_setAssociatedObject(pickerView, &PickerViewBinderDataSourceAssociationKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        if pickerView.reactive.hasProtocolProxy(for: UIPickerViewDataSource.self) {
            pickerView.reactive.dataSource.forwardTo = self
        } else {
            pickerView.dataSource = self
        }

        if pickerView.reactive.hasProtocolProxy(for: UIPickerViewDelegate.self) {
            pickerView.reactive.delegate.forwardTo = self
        } else {
            pickerView.delegate = self
        }
    }
}

#endif
