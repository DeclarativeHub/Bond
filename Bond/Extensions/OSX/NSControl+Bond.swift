//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Tony Arnold (@tonyarnold)
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

import Cocoa

@objc class NSControlBondHelper: NSObject
{
  weak var control: NSControl?
  let sink: AnyObject? -> Void
  
  init(control: NSControl, sink: AnyObject? -> Void) {
    self.control = control
    self.sink = sink
    super.init()
    control.target = self
    control.action = #selector(NSControlBondHelper.eventHandler(_:))
  }
  
  func eventHandler(sender: NSControl?) {
    sink(sender!.objectValue)
  }
  
  deinit {
    control?.target = nil
    control?.action = nil
  }
}


extension NSControl {

  private struct AssociatedKeys {
    static var ControlEventKey = "bnd_ControlEventKey"
    static var ControlBondHelperKey = "bnd_ControlBondHelperKey"
  }

  public var bnd_enabled: Observable<Bool> {
    return bnd_associatedObservableForValueForKey("enabled")
  }
  
  public var bnd_controlEvent: EventProducer<AnyObject?> {
    if let bnd_controlEvent: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.ControlEventKey) {
      return bnd_controlEvent as! EventProducer<AnyObject?>
    } else {
      var capturedSink: (AnyObject? -> Void)! = nil
      
      let bnd_controlEvent = EventProducer<AnyObject?> { sink in
        capturedSink = sink
        return nil
      }
      
      let controlHelper = NSControlBondHelper(control: self, sink: capturedSink)
      
      objc_setAssociatedObject(self, &AssociatedKeys.ControlBondHelperKey, controlHelper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      objc_setAssociatedObject(self, &AssociatedKeys.ControlEventKey, bnd_controlEvent, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return bnd_controlEvent
    }
  }
}

