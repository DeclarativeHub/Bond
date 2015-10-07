//
//  NSAppearanceCustomizationTests.swift
//  Bond
//
//  Created by Nikolai Vazquez on 10/6/15.
//  Copyright © 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSAppearanceCustomizationTests: XCTestCase {

  func testNSAppearanceCustomizationAppearanceBond() {
    let dynamicDriver = Observable<NSAppearance?>(NSAppearance(named: NSAppearanceNameVibrantDark))
    let view = NSView()

    view.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
    XCTAssertEqual(view.appearance, NSAppearance(named: NSAppearanceNameVibrantLight), "Initial value")

    dynamicDriver.bindTo(view.bnd_appearance)
    XCTAssertEqual(view.appearance, NSAppearance(named: NSAppearanceNameVibrantDark), "Value after binding")

    dynamicDriver.value = NSAppearance(named: NSAppearanceNameVibrantLight)
    XCTAssertEqual(view.appearance, NSAppearance(named: NSAppearanceNameVibrantLight), "Value after dynamic change")
  }

  func testFirstNSViewAppearanceBond() {
    let viewA = NSView()
    let viewB = NSView()

    viewB.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
    XCTAssertEqual(viewB.appearance, NSAppearance(named: NSAppearanceNameVibrantLight), "Initial value")

    viewA.bnd_appearance.bindTo(viewB.bnd_appearance)
    XCTAssertNil(viewB.appearance, "Value after binding")

    // viewB.appearance is nil after viewA.appearance is assigned.
//    viewA.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
//    XCTAssertEqual(viewB.appearance, NSAppearance(named: NSAppearanceNameVibrantDark), "Value after dynamic change")
  }

  func testSecondNSViewAppearanceBond() {
    let dynamicDriver = Observable<NSAppearance?>(NSAppearance(named: NSAppearanceNameVibrantDark))
    let viewA = NSView()
    let viewB = NSView()

    viewA.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
    XCTAssertEqual(viewA.appearance, NSAppearance(named: NSAppearanceNameVibrantLight), "Initial value")
    XCTAssertNil(viewB.appearance, "Initial value")

    dynamicDriver.bindTo(viewA.bnd_appearance)
    dynamicDriver.bindTo(viewB.bnd_appearance)
    XCTAssertEqual(viewA.appearance, NSAppearance(named: NSAppearanceNameVibrantDark), "Value after binding")

    dynamicDriver.value = NSAppearance(named: NSAppearanceNameVibrantLight)
    XCTAssertEqual(viewA.appearance, viewB.appearance, "Value after dynamic change")
  }

}
