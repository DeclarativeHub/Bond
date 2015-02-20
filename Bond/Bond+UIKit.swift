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

// NOTE!
//
// Due to unfortunate bug in Xcode, UIKit objects that can send events, like 
// UIButton (can send Tuuch Up Inside event) or UISlider (can send Value Changed
// event), must not have extensions that implement protocols, otherwise Interface
// Builder breaks and does not allow to connect actions to code.
//
// Bond uses protocols in order to have only one overload of ->> operator for all
// UIKit classes. Solution is to drop protocols and overload operator for each
// UIKit class that can 'Send events'.
//
// Hopefuly Apple will fix the bug soon.
//

import UIKit
import ObjectiveC


// MARK: UIView

private var backgroundColorBondHandleUIView: UInt8 = 0;
private var alphaBondHandleUIView: UInt8 = 0;
private var hiddenBondHandleUIView: UInt8 = 0;

extension UIView {
  public var backgroundColorBond: Bond<UIColor> {
    if let b: AnyObject = objc_getAssociatedObject(self, &backgroundColorBondHandleUIView) {
      return (b as? Bond<UIColor>)!
    } else {
      let b = Bond<UIColor>() { [unowned self] v in self.backgroundColor = v }
      objc_setAssociatedObject(self, &backgroundColorBondHandleUIView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var alphaBond: Bond<CGFloat> {
    if let b: AnyObject = objc_getAssociatedObject(self, &alphaBondHandleUIView) {
      return (b as? Bond<CGFloat>)!
    } else {
      let b = Bond<CGFloat>() { [unowned self] v in self.alpha = v }
      objc_setAssociatedObject(self, &alphaBondHandleUIView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var hiddenBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &hiddenBondHandleUIView) {
      return (b as? Bond<Bool>)!
    } else {
      let b = Bond<Bool>() { [unowned self] v in self.hidden = v }
      objc_setAssociatedObject(self, &hiddenBondHandleUIView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
}

// MARK: UISlider

@objc class SliderDynamicHelper
{
  weak var control: UISlider?
  var listener: (Float -> Void)?
  
  init(control: UISlider) {
    self.control = control
    control.addTarget(self, action: Selector("valueChanged:"), forControlEvents: .ValueChanged)
  }
  
  func valueChanged(slider: UISlider) {
    self.listener?(slider.value)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .ValueChanged)
  }
}

class SliderDynamic<T>: Dynamic<Float>
{
  let helper: SliderDynamicHelper
  
  init(control: UISlider) {
    self.helper = SliderDynamicHelper(control: control)
    super.init(control.value)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var designatedBondHandleUISlider: UInt8 = 0;

extension UISlider /*: Dynamical, Bondable */ {
  public func valueDynamic() -> Dynamic<Float> {
    return SliderDynamic<Float>(control: self)
  }
  
  public var valueBond: Bond<Float> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUISlider) {
      return (b as? Bond<Float>)!
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

public func ->> (left: UISlider, right: Bond<Float>) {
  left.designatedDynamic() ->> right
}

public func ->> <U: Bondable where U.BondType == Float>(left: UISlider, right: U) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: UISlider, right: UISlider) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: Dynamic<Float>, right: UISlider) {
  left ->> right.designatedBond
}

// MARK: UILabel

private var designatedBondHandleUILabel: UInt8 = 0;

extension UILabel: Bondable {
  public var textBond: Bond<String> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUILabel) {
      return (b as? Bond<String>)!
    } else {
      let b = Bond<String>() { [unowned self] v in self.text = v }
      objc_setAssociatedObject(self, &designatedBondHandleUILabel, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var designatedBond: Bond<String> {
    return self.textBond
  }
}

// MARK: UIProgressView

private var designatedBondHandleUIProgressView: UInt8 = 0;

extension UIProgressView: Bondable {
  public var progressBond: Bond<Float> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUIProgressView) {
      return (b as? Bond<Float>)!
    } else {
      let b = Bond<Float>() { [unowned self] v in self.progress = v }
      objc_setAssociatedObject(self, &designatedBondHandleUIProgressView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }

  public var designatedBond: Bond<Float> {
    return self.progressBond
  }
}

// MARK: UIImageView
var associatedObjectHandleUIImageView: UInt8 = 0;

extension UIImageView: Bondable {
  public var imageBond: Bond<UIImage?> {
    if let b: AnyObject = objc_getAssociatedObject(self, &associatedObjectHandleUIImageView) {
      return (b as? Bond<UIImage?>)!
    } else {
      let b = Bond<UIImage?>() { [unowned self] v in self.image = v }
      objc_setAssociatedObject(self, &associatedObjectHandleUIImageView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var designatedBond: Bond<UIImage?> {
    return self.imageBond
  }
}

// MARK: UIButton

@objc class ButtonDynamicHelper
{
  weak var control: UIButton?
  var listener: (UIControlEvents -> Void)?
  
  init(control: UIButton) {
    self.control = control
    control.addTarget(self, action: Selector("touchDown:"), forControlEvents: .TouchDown)
    control.addTarget(self, action: Selector("touchUpInside:"), forControlEvents: .TouchUpInside)
    control.addTarget(self, action: Selector("touchUpOutside:"), forControlEvents: .TouchUpOutside)
    control.addTarget(self, action: Selector("touchCancel:"), forControlEvents: .TouchCancel)
  }

  func touchDown(control: UIButton) {
    self.listener?(.TouchDown)
  }
  
  func touchUpInside(control: UIButton) {
    self.listener?(.TouchUpInside)
  }
  
  func touchUpOutside(control: UIButton) {
    self.listener?(.TouchUpOutside)
  }
  
  func touchCancel(control: UIButton) {
    self.listener?(.TouchCancel)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .AllEvents)
  }
}

class ButtonDynamic<T>: Dynamic<UIControlEvents>
{
  let helper: ButtonDynamicHelper
  
  init(control: UIButton) {
    self.helper = ButtonDynamicHelper(control: control)
    super.init(UIControlEvents.allZeros)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var enabledBondHandleUIButton: UInt8 = 0;
private var titleBondHandleUIButton: UInt8 = 0;
private var imageForNormalStateBondHandleUIButton: UInt8 = 0;

extension UIButton /*: Dynamical, Bondable */ {
  public func eventDynamic() -> Dynamic<UIControlEvents> {
    return ButtonDynamic<UIControlEvents>(control: self)
  }
  
  public var enabledBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &enabledBondHandleUIButton) {
      return (b as? Bond<Bool>)!
    } else {
      let b = Bond<Bool>() { [unowned self] v in self.enabled = v }
      objc_setAssociatedObject(self, &enabledBondHandleUIButton, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var titleBond: Bond<String> {
    if let b: AnyObject = objc_getAssociatedObject(self, &titleBondHandleUIButton) {
      return (b as? Bond<String>)!
    } else {
      let b = Bond<String>() { [unowned self] v in
        if let label = self.titleLabel {
          label.text = v
        }
      }
      objc_setAssociatedObject(self, &titleBondHandleUIButton, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var imageForNormalStateBond: Bond<UIImage?> {
    if let b: AnyObject = objc_getAssociatedObject(self, &imageForNormalStateBondHandleUIButton) {
      return (b as? Bond<UIImage?>)!
    } else {
      let b = Bond<UIImage?>() { [unowned self] img in self.setImage(img, forState: .Normal) }
      objc_setAssociatedObject(self, &imageForNormalStateBondHandleUIButton, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public func designatedDynamic() -> Dynamic<UIControlEvents> {
    return self.eventDynamic()
  }
  
  public var designatedBond: Bond<Bool> {
    return self.enabledBond
  }
}

public func ->> (left: UIButton, right: Bond<UIControlEvents>) {
  left.designatedDynamic() ->> right
}

public func ->> <U: Bondable where U.BondType == UIControlEvents>(left: UIButton, right: U) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == Bool>(left: T, right: UIButton) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: Dynamic<Bool>, right: UIButton) {
  left ->> right.designatedBond
}

// MARK: UISwitch

@objc class SwitchDynamicHelper
{
  weak var control: UISwitch?
  var listener: (Bool -> Void)?
  
  init(control: UISwitch) {
    self.control = control
    control.addTarget(self, action: Selector("valueChanged:"), forControlEvents: .ValueChanged)
  }
  
  func valueChanged(control: UISwitch) {
    self.listener?(control.on)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .ValueChanged)
  }
}

class SwitchDynamic<T>: Dynamic<Bool>
{
  let helper: SwitchDynamicHelper
  
  init(control: UISwitch) {
    self.helper = SwitchDynamicHelper(control: control)
    super.init(control.on)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var designatedBondHandleUISwitch: UInt8 = 0;

extension UISwitch /*: Dynamical, Bondable */ {
  public func onDynamic() -> Dynamic<Bool> {
    return SwitchDynamic<Bool>(control: self)
  }
  
  public var onBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUISwitch) {
      return (b as? Bond<Bool>)!
    } else {
      let b = Bond<Bool>() { [unowned self] v in self.on = v }
      objc_setAssociatedObject(self, &designatedBondHandleUISwitch, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public func designatedDynamic() -> Dynamic<Bool> {
    return self.onDynamic()
  }
  
  public var designatedBond: Bond<Bool> {
    return self.onBond
  }
}

public func ->> (left: UISwitch, right: Bond<Bool>) {
  left.designatedDynamic() ->> right
}

public func ->> <U: Bondable where U.BondType == Bool>(left: UISwitch, right: U) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: UISwitch, right: UIButton) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: UISwitch, right: UISwitch) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == Bool>(left: T, right: UISwitch) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: Dynamic<Bool>, right: UISwitch) {
  left ->> right.designatedBond
}

// MARK: UITextField

@objc class TextFieldDynamicHelper
{
  weak var control: UITextField?
  var listener: (String -> Void)?
  
  init(control: UITextField) {
    self.control = control
    control.addTarget(self, action: Selector("editingChanged:"), forControlEvents: .EditingChanged)
  }
  
  func editingChanged(control: UITextField) {
    self.listener?(control.text ?? "")
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .EditingChanged)
  }
}

class TextFieldDynamic<T>: Dynamic<String>
{
  let helper: TextFieldDynamicHelper
  
  init(control: UITextField) {
    self.helper = TextFieldDynamicHelper(control: control)
    super.init(control.text)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var designatedBondHandleUITextField: UInt8 = 0;

extension UITextField /*: Dynamical, Bondable */ {
  public func textDynamic() -> Dynamic<String> {
    return TextFieldDynamic<String>(control: self)
  }
  
  public var textBond: Bond<String> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUITextField) {
      return (b as? Bond<String>)!
    } else {
      let b = Bond<String>() { [unowned self] v in self.text = v }
      objc_setAssociatedObject(self, &designatedBondHandleUITextField, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public func designatedDynamic() -> Dynamic<String> {
    return self.textDynamic()
  }
  
  public var designatedBond: Bond<String> {
    return self.textBond
  }
}

public func ->> (left: UITextField, right: Bond<String>) {
  left.designatedDynamic() ->> right
}

public func ->> <U: Bondable where U.BondType == String>(left: UITextField, right: U) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: UITextField, right: UITextField) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: UITextField, right: UILabel) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> <T: Dynamical where T.DynamicType == String>(left: T, right: UITextField) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: Dynamic<String>, right: UITextField) {
  left ->> right.designatedBond
}

// MARK: UIDatePicker

@objc class DatePickerDynamicHelper
{
  weak var control: UIDatePicker?
  var listener: (NSDate -> Void)?
  
  init(control: UIDatePicker) {
    self.control = control
    control.addTarget(self, action: Selector("valueChanged:"), forControlEvents: .ValueChanged)
  }
  
  func valueChanged(control: UIDatePicker) {
    self.listener?(control.date)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: .ValueChanged)
  }
}

class DatePickerDynamic<T>: Dynamic<NSDate>
{
  let helper: DatePickerDynamicHelper
  
  init(control: UIDatePicker) {
    self.helper = DatePickerDynamicHelper(control: control)
    super.init(control.date)
    self.helper.listener =  { [unowned self] in self.value = $0 }
  }
}

private var designatedBondHandleUIDatePicker: UInt8 = 0;

extension UIDatePicker /*: Dynamical, Bondable */ {
  public func dateDynamic() -> Dynamic<NSDate> {
    return DatePickerDynamic<NSDate>(control: self)
  }
  
  public var dateBond: Bond<NSDate> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUIDatePicker) {
      return (b as? Bond<NSDate>)!
    } else {
      let b = Bond<NSDate>() { [unowned self] v in self.date = v }
      objc_setAssociatedObject(self, &designatedBondHandleUIDatePicker, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public func designatedDynamic() -> Dynamic<NSDate> {
    return self.dateDynamic()
  }
  
  public var designatedBond: Bond<NSDate> {
    return self.dateBond
  }
}

public func ->> (left: UIDatePicker, right: Bond<NSDate>) {
  left.designatedDynamic() ->> right
}

public func ->> <U: Bondable where U.BondType == NSDate>(left: UIDatePicker, right: U) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: UIDatePicker, right: UIDatePicker) {
  left.designatedDynamic() ->> right.designatedBond
}

public func ->> (left: Dynamic<NSDate>, right: UIDatePicker) {
  left ->> right.designatedBond
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

extension UITableView /*: Bondable */ {
  public var dataSourceBond: Bond<Array<UITableViewCell>> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUITableView) {
      return (b as? TableViewBond<UITableViewCell>)!
    } else {
      let b = TableViewBond<UITableViewCell>(tableView: self)
      objc_setAssociatedObject(self, &designatedBondHandleUITableView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return b
    }
  }
  
  public var designatedBond: Bond<Array<UITableViewCell>> {
    return self.dataSourceBond
  }
}

public func ->> (left: Dynamic<Array<UITableViewCell>>, right: UITableView) {
  left ->> right.designatedBond
}

// MARK: UIRefreshControl

private var designatedBondHandleUIRefreshControl: UInt8 = 0;

extension UIRefreshControl {
  public var refreshingBond: Bond<Bool> {
    if let b: AnyObject = objc_getAssociatedObject(self, &designatedBondHandleUIRefreshControl) {
      return (b as? Bond<Bool>)!
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
  
  public var designatedBond: Bond<Bool> {
    return self.refreshingBond
  }
}

public func ->> (left: Dynamic<Bool>, right: UIRefreshControl) {
  left ->> right.designatedBond
}

// MARK: UIBarItem

private var enabledBondHandleUIBarItem: UInt8 = 0;
private var titleBondHandleUIBarItem: UInt8 = 0;
private var imageBondHandleUIBarItem: UInt8 = 0;

extension UIBarItem: Bondable {
    
    public var enabledBond: Bond<Bool> {
        if let b: AnyObject = objc_getAssociatedObject(self, &enabledBondHandleUIBarItem) {
            return (b as? Bond<Bool>)!
        } else {
            let b = Bond<Bool>() { [unowned self] v in self.enabled = v }
            objc_setAssociatedObject(self, &enabledBondHandleUIBarItem, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return b
        }
    }
    
    public var titleBond: Bond<String> {
        if let b: AnyObject = objc_getAssociatedObject(self, &titleBondHandleUIBarItem) {
            return (b as? Bond<String>)!
        } else {
            let b = Bond<String>() { [unowned self] v in
                self.title = v
            }
            objc_setAssociatedObject(self, &titleBondHandleUIBarItem, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return b
        }
    }
    
    public var imageBond: Bond<UIImage?> {
        if let b: AnyObject = objc_getAssociatedObject(self, &imageBondHandleUIBarItem) {
            return (b as? Bond<UIImage?>)!
        } else {
            let b = Bond<UIImage?>() { [unowned self] img in self.image = img }
            objc_setAssociatedObject(self, &imageBondHandleUIBarItem, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return b
        }
    }
    
    public var designatedBond: Bond<Bool> {
        return self.enabledBond
    }
}

// MARK: UITextView

private var textBondHandleUITextView: UInt8 = 0;

extension UITextView: Bondable {
    
    public var textBond: Bond<String> {
        if let b: AnyObject = objc_getAssociatedObject(self, &textBondHandleUITextView) {
            return (b as? Bond<String>)!
        } else {
            let b = Bond<String>() { [unowned self] v in
                self.text = v
            }
            objc_setAssociatedObject(self, &textBondHandleUITextView, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return b
        }
    }

    public var designatedBond: Bond<String> {
        return self.textBond
    }
}

