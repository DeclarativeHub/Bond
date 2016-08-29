//
//  BondTests.swift
//  BondTests
//
//  Created by Srdan Rasic on 19/07/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import XCTest
import ReactiveKit

class BondTests: XCTestCase {

  func testUIView() {
    let view = UIView()

    Signal1.just(UIColor.red).bind(to: view.bnd_backgroundColor)
    XCTAssertEqual(view.backgroundColor!, UIColor.red)

    Signal1.just(0.3).bind(to: view.bnd_alpha)
    XCTAssertEqual(view.alpha, 0.3)

    Signal1.just(true).bind(to: view.bnd_isHidden)
    XCTAssertEqual(view.isHidden, true)

    Signal1.just(true).bind(to: view.bnd_isUserInteractionEnabled)
    XCTAssertEqual(view.isUserInteractionEnabled, true)

    Signal1.just(UIColor.red).bind(to: view.bnd_tintColor)
    XCTAssertEqual(view.tintColor, UIColor.red)
  }

  func testUIActivityIndicatorView() {
    let subject = PublishSubject1<Bool>()

    let view = UIActivityIndicatorView()
    subject.bind(to: view.bnd_animating)

    XCTAssertEqual(view.isAnimating, false)

    subject.next(true)
    XCTAssertEqual(view.isAnimating, true)

    subject.next(false)
    XCTAssertEqual(view.isAnimating, false)
  }

  func testUIBarItem() {
    let view = UIBarButtonItem()

    Signal1.just("test").bind(to: view.bnd_title)
    XCTAssertEqual(view.title!, "test")

    let image = UIImage()
    Signal1.just(image).bind(to: view.bnd_image)
    XCTAssertEqual(view.image!, image)

    Signal1.just(true).bind(to: view.bnd_isEnabled)
    XCTAssertEqual(view.isEnabled, true)
    Signal1.just(false).bind(to: view.bnd_isEnabled)
    XCTAssertEqual(view.isEnabled, false)
  }

  func testUIButton() {
    let view = UIButton()

    Signal1.just("test").bind(to: view.bnd_title)
    XCTAssertEqual(view.titleLabel?.text, "test")

    Signal1.just(true).bind(to: view.bnd_isSelected)
    XCTAssertEqual(view.isSelected, true)
    Signal1.just(false).bind(to: view.bnd_isSelected)
    XCTAssertEqual(view.isSelected, false)

    Signal1.just(true).bind(to: view.bnd_isHighlighted)
    XCTAssertEqual(view.isHighlighted, true)
    Signal1.just(false).bind(to: view.bnd_isHighlighted)
    XCTAssertEqual(view.isHighlighted, false)

    view.bnd_tap.expectNext([(), ()])
    view.sendActions(for: UIControlEvents.touchUpInside)
    view.sendActions(for: UIControlEvents.touchUpInside)
    view.sendActions(for: UIControlEvents.touchUpOutside)
  }
}

