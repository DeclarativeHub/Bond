//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Jens Nilsson (@phiberjenz)
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

extension UISegmentedControl {
    
  private struct AssociatedKeys {
    static var SelectedSegmentIndexKey = "bnd_SelectedSegmentIndexKey"
  }
    
  public var bnd_selectedSegmentIndex: Observable<Int> {
    if let bnd_selectedSegmentIndex: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.SelectedSegmentIndexKey) {
      return bnd_selectedSegmentIndex as! Observable<Int>
    } else {
      let bnd_selectedSegmentIndex = Observable<Int>(self.selectedSegmentIndex)
      objc_setAssociatedObject(self, &AssociatedKeys.SelectedSegmentIndexKey, bnd_selectedSegmentIndex, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
      var updatingFromSelf: Bool = false
            
      bnd_selectedSegmentIndex.observeNew { [weak self] selectedSegmentIndex in
        if !updatingFromSelf {
          self?.selectedSegmentIndex = selectedSegmentIndex
        }
      }
            
      self.bnd_controlEvent.filter { $0 == UIControlEvents.ValueChanged }.observe { [weak self, weak bnd_selectedSegmentIndex] event in
        guard let unwrappedSelf = self, let bnd_selectedSegmentIndex = bnd_selectedSegmentIndex else { return }
        updatingFromSelf = true
        bnd_selectedSegmentIndex.next(unwrappedSelf.selectedSegmentIndex)
        updatingFromSelf = false
      }
            
      return bnd_selectedSegmentIndex
    }
  }
}
