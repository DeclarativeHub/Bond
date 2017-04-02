//
//  UIAI.swift
//  Bond
//
//  Created by Srdan Rasic on 02/04/2017.
//  Copyright © 2017 Swift Bond. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import ReactiveKit

extension ReactiveExtensions where Base: Deallocatable, Base: UIAccessibilityIdentification {

  var accessibilityIdentifier: Bond<String?> {
    return bond(context: .immediateOnMain) {
      $0.accessibilityIdentifier = $1
    }
  }
}

#endif
