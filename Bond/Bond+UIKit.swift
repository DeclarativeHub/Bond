//
//  Bond+UIKit.swift
//  Bond
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
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
import ObjectiveC


// MARK: Common

protocol ControlDynamicHelper
{
  typealias T
  var value: T { get }
  var listener: (T -> Void)? { get set }
}

class ControlDynamic<T, U: ControlDynamicHelper where U.T == T>: Dynamic<T>
{
  var helper: U
  
  init(helper: U) {
    self.helper = helper
    super.init(helper.value)
    self.helper.listener =  { [unowned self] in
      self.value = $0
    }
  }
}

// MARK: UISlider

@objc class SliderDynamicHelper: NSObject, ControlDynamicHelper {
  weak var sliderControl: UISlider?
  var value: Float {
    return sliderControl?.value ?? 0
  }
  
  var listener: (Float -> Void)?
  
  init(sliderControl: UISlider) {
    self.sliderControl = sliderControl
    super.init()
    sliderControl.addTarget(self, action: Selector("valueChanged:"), forControlEvents: .ValueChanged)
  }
  
  func valueChanged(slider: UISlider) {
    self.listener?(slider.value)
  }
  
  deinit {
    sliderControl?.removeTarget(self, action: nil, forControlEvents: .ValueChanged)
  }
}

private var designatedBondHandleUISlider: UInt8 = 0;

extension UISlider: Dynamical, Bondable {
  public func valueDynamic() -> Dynamic<Float> {
    return ControlDynamic<Float, SliderDynamicHelper>(helper: SliderDynamicHelper(sliderControl: self))
  }
  
  public var valueBond: Bond<Float> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUISlider) {
      return b as Bond<Float>
    } else {
      let b = Bond() { v in self.value = v }
      objc_setAssociatedObject(self, &designatedBondHandleUISlider, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public func designatedDynamic() -> Dynamic<Float> {
    return self.valueDynamic()
  }
  
  public var designatedBond: Bond<Float> {
    return self.valueBond
  }
}


// MARK: UILabel

private var designatedBondHandleUILabel: UInt8 = 0;

extension UILabel: Bondable {
  public var designatedBond: Bond<String> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUILabel) {
      return b as Bond<String>
    } else {
      let b = Bond<String>() { [unowned self] v in self.text = v }
      objc_setAssociatedObject(self, &designatedBondHandleUILabel, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
}

// MARK: UIProgressView

private var designatedBondHandleUIProgressView: UInt8 = 0;

extension UIProgressView: Bondable {
  public var designatedBond: Bond<Float> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUIProgressView) {
      return b as Bond<Float>
    } else {
      let b = Bond<Float>() { [unowned self] v in self.progress = v }
      objc_setAssociatedObject(self, &designatedBondHandleUIProgressView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
}

// MARK: UIImageView
var associatedObjectHandleUIImageView: UInt8 = 0;

extension UIImageView: Bondable {
  public var designatedBond: Bond<UIImage?> {
    if let b: AnyObject = objc_getAssociatedObject(self, &associatedObjectHandleUIImageView) {
      return b as Bond<UIImage?>
    } else {
      let b = Bond<UIImage?>() { [unowned self] v in self.image = v }
      objc_setAssociatedObject(self, &associatedObjectHandleUIImageView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
}

// MARK: UIButton

@objc class ButtonDynamicHelper: NSObject, ControlDynamicHelper {
  weak var control: UIButton?
  var value: UIControlEvents = UIControlEvents.allZeros
  
  var listener: (UIControlEvents -> Void)?
  
  init(control: UIButton) {
    self.control = control
    super.init()
    control.addTarget(self, action: Selector("touchDown:"), forControlEvents: .TouchDown)
    control.addTarget(self, action: Selector("touchUpInside:"), forControlEvents: .TouchUpInside)
    control.addTarget(self, action: Selector("touchUpOutside:"), forControlEvents: .TouchUpOutside)
    control.addTarget(self, action: Selector("touchCancel:"), forControlEvents: .TouchCancel)
  }
  
  func touchDown(control: UIButton) {
    self.value = .TouchDown
    self.listener?(self.value)
  }
  
  func touchUpInside(control: UIButton) {
    self.value = .TouchUpInside
    self.listener?(self.value)
  }
  
  func touchUpOutside(control: UIButton) {
    self.value = .TouchUpOutside
    self.listener?(self.value)
  }
  
  func touchCancel(control: UIButton) {
    self.value = .TouchCancel
    self.listener?(self.value)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .AllEvents)
  }
}

private var designatedBondHandleUIButton: UInt8 = 0;

extension UIButton: Dynamical, Bondable {
  public func designatedDynamic() -> Dynamic<UIControlEvents> {
    return ControlDynamic<UIControlEvents, ButtonDynamicHelper>(helper: ButtonDynamicHelper(control: self))
  }
  
  public var designatedBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUIButton) {
      return b as Bond<Bool>
    } else {
      let b = Bond<Bool>() { [unowned self] v in self.enabled = v }
      objc_setAssociatedObject(self, &designatedBondHandleUIButton, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
}

// MARK: UISwitch

@objc class SwitchDynamicHelper: NSObject, ControlDynamicHelper {
  weak var control: UISwitch?
  
  var value: Bool {
    return control?.on ?? false
  }
  
  var listener: (Bool -> Void)?
  
  init(control: UISwitch) {
    self.control = control
    super.init()
    control.addTarget(self, action: Selector("valueChanged:"), forControlEvents: .ValueChanged)
  }
  
  func valueChanged(control: UISwitch) {
    self.listener?(control.on)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .ValueChanged)
  }
}

private var designatedBondHandleUISwitch: UInt8 = 0;

extension UISwitch: Dynamical, Bondable {
  public func designatedDynamic() -> Dynamic<Bool> {
    return ControlDynamic<Bool, SwitchDynamicHelper>(helper: SwitchDynamicHelper(control: self))
  }
  
  public var designatedBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUISwitch) {
      return b as Bond<Bool>
    } else {
      let b = Bond<Bool>() { [unowned self] v in self.on = v }
      objc_setAssociatedObject(self, &designatedBondHandleUISwitch, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
}

// MARK: UITextField

@objc class TextFieldDynamicHelper: NSObject, ControlDynamicHelper {
  weak var control: UITextField?
  
  var value: String {
    return control?.text ?? ""
  }
  
  var listener: (String -> Void)?
  
  init(control: UITextField) {
    self.control = control
    super.init()
    control.addTarget(self, action: Selector("editingChanged:"), forControlEvents: .EditingChanged)
  }
  
  func editingChanged(control: UITextField) {
    self.listener?(control.text ?? "")
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .EditingChanged)
  }
}

private var designatedBondHandleUITextField: UInt8 = 0;

extension UITextField: Dynamical, Bondable {
  public func designatedDynamic() -> Dynamic<String> {
    return ControlDynamic<String, TextFieldDynamicHelper>(helper: TextFieldDynamicHelper(control: self))
  }
  
  public var designatedBond: Bond<String> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUITextField) {
      return b as Bond<String>
    } else {
      let b = Bond<String>() { [unowned self] v in self.text = v }
      objc_setAssociatedObject(self, &designatedBondHandleUITextField, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
}

// MARK: UIDatePicker

@objc class DatePickerDynamicHelper: NSObject, ControlDynamicHelper {
  weak var control: UIDatePicker?
  
  var value: NSDate {
    return control?.date ?? NSDate()
  }
  
  var listener: (NSDate -> Void)?
  
  init(control: UIDatePicker) {
    self.control = control
    super.init()
    control.addTarget(self, action: Selector("valueChanged:"), forControlEvents: .ValueChanged)
  }
  
  func valueChanged(control: UIDatePicker) {
    self.listener?(control.date)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .ValueChanged)
  }
}

private var designatedBondHandleUIDatePicker: UInt8 = 0;

extension UIDatePicker: Dynamical, Bondable {
  public func designatedDynamic() -> Dynamic<NSDate> {
    return ControlDynamic<NSDate, DatePickerDynamicHelper>(helper: DatePickerDynamicHelper(control: self))
  }
  
  public var designatedBond: Bond<NSDate> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUIDatePicker) {
      return b as Bond<NSDate>
    } else {
      let b = Bond<NSDate>() { [unowned self] v in self.date = v }
      objc_setAssociatedObject(self, &designatedBondHandleUIDatePicker, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
}

// MARK: UITableView

@objc class TableViewDynamicArrayDataSource: NSObject, UITableViewDataSource {
  var dynamic: DynamicArray<UITableViewCell>
  
  init(dynamic: DynamicArray<UITableViewCell>) {
    self.dynamic = dynamic
    super.init()
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.dynamic.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    return self.dynamic[indexPath.item]
  }
}

public class TableViewBond<T>: ArrayBond<UITableViewCell> {
  weak var tableView: UITableView?
  var dataSource: TableViewDynamicArrayDataSource?
  
  init(tableView: UITableView) {
    self.tableView = tableView
    super.init()
    
    self.insertListener = { i in
      self.tableView?.beginUpdates()
      self.tableView?.insertRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: 0) },
        withRowAnimation: UITableViewRowAnimation.Automatic)
      self.tableView?.endUpdates()
    }
    
    self.removeListener = { i, o in
      self.tableView?.beginUpdates()
      self.tableView?.deleteRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: 0) },
        withRowAnimation: UITableViewRowAnimation.Automatic)
      self.tableView?.endUpdates()
    }
    
    self.updateListener = { i in
      self.tableView?.beginUpdates()
      self.tableView?.reloadRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: 0) },
        withRowAnimation: UITableViewRowAnimation.Automatic)
      self.tableView?.endUpdates()
    }
  }
  
  public override func bind(dynamic: Dynamic<Array<UITableViewCell>>, fire: Bool) {
    super.bind(dynamic, fire: false)
    if let dynamic = dynamic as? DynamicArray {
      dataSource = TableViewDynamicArrayDataSource(dynamic: dynamic)
      tableView?.dataSource = dataSource
      tableView?.reloadData()
    }
  }
}

private var designatedBondHandleUITableView: UInt8 = 0;

extension UITableView: Bondable {
  public var designatedBond: Bond<Array<UITableViewCell>> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUITableView) {
      return b as TableViewBond<UITableViewCell>
    } else {
      let b = TableViewBond<UITableViewCell>(tableView: self)
      objc_setAssociatedObject(self, &designatedBondHandleUITableView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
}


// MARK: UIRefreshControl

private var designatedBondHandleUIRefreshControl: UInt8 = 0;

extension UIRefreshControl: Bondable {
  
  public var designatedBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUIRefreshControl) {
      return b as Bond<Bool>
    } else {
      let b = Bond<Bool>() { [unowned self] v in
        if (v) {
          self.beginRefreshing()
        } else {
          self.endRefreshing()
        }
      }
      objc_setAssociatedObject(self, &designatedBondHandleUIRefreshControl, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
}


