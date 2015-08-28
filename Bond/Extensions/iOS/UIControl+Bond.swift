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

@objc class UIControlBondHelper: NSObject
{
  weak var control: UIControl?
  let sink: UIControlEvents -> ()
  
  init(control: UIControl, sink: UIControlEvents -> ()) {
    self.control = control
    self.sink = sink
    super.init()
    control.addTarget(self, action: Selector("eventHandlerTouchDown"), forControlEvents: UIControlEvents.TouchDown)
    control.addTarget(self, action: Selector("eventHandlerTouchDownRepeat"), forControlEvents: UIControlEvents.TouchDownRepeat)
    control.addTarget(self, action: Selector("eventHandlerTouchDragInside"), forControlEvents: UIControlEvents.TouchDragInside)
    control.addTarget(self, action: Selector("eventHandlerTouchDragOutside"), forControlEvents: UIControlEvents.TouchDragOutside)
    control.addTarget(self, action: Selector("eventHandlerTouchDragEnter"), forControlEvents: UIControlEvents.TouchDragEnter)
    control.addTarget(self, action: Selector("eventHandlerTouchDragExit"), forControlEvents: UIControlEvents.TouchDragExit)
    control.addTarget(self, action: Selector("eventHandlerTouchUpInside"), forControlEvents: UIControlEvents.TouchUpInside)
    control.addTarget(self, action: Selector("eventHandlerTouchUpOutside"), forControlEvents: UIControlEvents.TouchUpOutside)
    control.addTarget(self, action: Selector("eventHandlerTouchCancel"), forControlEvents: UIControlEvents.TouchCancel)
    control.addTarget(self, action: Selector("eventHandlerValueChanged"), forControlEvents: UIControlEvents.ValueChanged)
    control.addTarget(self, action: Selector("eventHandlerEditingDidBegin"), forControlEvents: UIControlEvents.EditingDidBegin)
    control.addTarget(self, action: Selector("eventHandlerEditingChanged"), forControlEvents: UIControlEvents.EditingChanged)
    control.addTarget(self, action: Selector("eventHandlerEditingDidEnd"), forControlEvents: UIControlEvents.EditingDidEnd)
    control.addTarget(self, action: Selector("eventHandlerEditingDidEndOnExit"), forControlEvents: UIControlEvents.EditingDidEndOnExit)
  }
  
  func eventHandlerTouchDown() {
    sink(.TouchDown)
  }
  
  func eventHandlerTouchDownRepeat() {
    sink(.TouchDownRepeat)
  }
  
  func eventHandlerTouchDragInside() {
    sink(.TouchDragInside)
  }
  
  func eventHandlerTouchDragOutside() {
    sink(.TouchDragOutside)
  }
  
  func eventHandlerTouchDragEnter() {
    sink(.TouchDragEnter)
  }
  
  func eventHandlerTouchDragExit() {
    sink(.TouchDragExit)
  }
  
  func eventHandlerTouchUpInside() {
    sink(.TouchUpInside)
  }
  
  func eventHandlerTouchUpOutside() {
    sink(.TouchUpOutside)
  }
  
  func eventHandlerTouchCancel() {
    sink(.TouchCancel)
  }
  
  func eventHandlerValueChanged() {
    sink(.ValueChanged)
  }
  
  func eventHandlerEditingDidBegin() {
    sink(.EditingDidBegin)
  }
  
  func eventHandlerEditingChanged() {
    sink(.EditingChanged)
  }
  
  func eventHandlerEditingDidEnd() {
    sink(.EditingDidEnd)
  }
  
  func eventHandlerEditingDidEndOnExit() {
    sink(.EditingDidEndOnExit)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, forControlEvents: UIControlEvents.AllEvents)
  }
}

extension UIControl {
  
  private struct AssociatedKeys {
    static var ControlEventKey = "bnd_ControlEventKey"
    static var ControlBondHelperKey = "bnd_ControlBondHelperKey"
  }
  
  public var bnd_controlEvent: EventProducer<UIControlEvents> {
    if let bnd_controlEvent: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.ControlEventKey) {
      return bnd_controlEvent as! EventProducer<UIControlEvents>
    } else {
      var capturedSink: (UIControlEvents -> ())! = nil
      
      let bnd_controlEvent = EventProducer<UIControlEvents> { sink in
        capturedSink = sink
        return nil
      }
      
      let controlHelper = UIControlBondHelper(control: self, sink: capturedSink)
      
      objc_setAssociatedObject(self, &AssociatedKeys.ControlBondHelperKey, controlHelper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      objc_setAssociatedObject(self, &AssociatedKeys.ControlEventKey, bnd_controlEvent, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return bnd_controlEvent
    }
  }
  
  public var bnd_enabled: Observable<Bool> {
    return bnd_associatedObservableForValueForKey("enabled")
  }
}
