//
//  BondTests.swift
//  BondTests
//
//  Created by Srdan Rasic on 19/07/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

#if os(iOS) || os(tvOS)

import XCTest
import ReactiveKit
@testable import Bond

class BondTests: XCTestCase {

    func testUIView() {
        let view = UIView()

        SafeSignal(just: UIColor.red).bind(to: view.reactive.backgroundColor)
        XCTAssertEqual(view.backgroundColor!, UIColor.red)

        SafeSignal(just: 0.3).bind(to: view.reactive.alpha)
        XCTAssertEqual(view.alpha, 0.3)

        SafeSignal(just: true).bind(to: view.reactive.isHidden)
        XCTAssertEqual(view.isHidden, true)

        SafeSignal(just: true).bind(to: view.reactive.isUserInteractionEnabled)
        XCTAssertEqual(view.isUserInteractionEnabled, true)

        SafeSignal(just: UIColor.red).bind(to: view.reactive.tintColor)
        XCTAssertEqual(view.tintColor, UIColor.red)
    }

    func testUIActivityIndicatorView() {
        let subject = PassthroughSubject<Bool, Never>()

        let view = UIActivityIndicatorView()
        subject.bind(to: view.reactive.isAnimating)

        XCTAssertEqual(view.isAnimating, false)

        subject.send(true)
        XCTAssertEqual(view.isAnimating, true)

        subject.send(false)
        XCTAssertEqual(view.isAnimating, false)
    }

    func testUIBarItem() {
        let view = UIBarButtonItem()

        SafeSignal(just: "test").bind(to: view.reactive.title)
        XCTAssertEqual(view.title!, "test")

        let image = UIImage()
        SafeSignal(just: image).bind(to: view.reactive.image)
        XCTAssertEqual(view.image!, image)

        SafeSignal(just: true).bind(to: view.reactive.isEnabled)
        XCTAssertEqual(view.isEnabled, true)
        SafeSignal(just: false).bind(to: view.reactive.isEnabled)
        XCTAssertEqual(view.isEnabled, false)

        view.reactive.tap.expectNext([(), ()])
        view.reactive.tap.expectNext([(), ()]) // second observer
        _ = view.target!.perform(view.action!)
        _ = view.target!.perform(view.action!)
    }

    func testUIButton() {
        let view = UIButton()

        SafeSignal(just: "test").bind(to: view.reactive.title)
        XCTAssertEqual(view.titleLabel?.text, "test")

        SafeSignal(just: true).bind(to: view.reactive.isSelected)
        XCTAssertEqual(view.isSelected, true)
        SafeSignal(just: false).bind(to: view.reactive.isSelected)
        XCTAssertEqual(view.isSelected, false)

        SafeSignal(just: true).bind(to: view.reactive.isHighlighted)
        XCTAssertEqual(view.isHighlighted, true)
        SafeSignal(just: false).bind(to: view.reactive.isHighlighted)
        XCTAssertEqual(view.isHighlighted, false)

        let image = UIImage()
        let image2 = UIImage()

        SafeSignal(just: image).bind(to: view.reactive.backgroundImage)
        XCTAssertEqual(view.backgroundImage(for: .normal), image)

        SafeSignal(just: image2).bind(to: view.reactive.image)
        XCTAssertEqual(view.image(for: .normal), image2)

        view.reactive.tap.expectNext([(), ()])
        view.sendActions(for: .touchUpInside)
        view.sendActions(for: .touchUpInside)
        view.sendActions(for: .touchUpOutside)
    }

    func testUIControl() {
        let view = UIControl()

        SafeSignal(just: true).bind(to: view.reactive.isEnabled)
        XCTAssertEqual(view.isEnabled, true)
        SafeSignal(just: false).bind(to: view.reactive.isEnabled)
        XCTAssertEqual(view.isEnabled, false)

        view.reactive.controlEvents(UIControl.Event.touchUpInside).expectNext([(), ()])
        view.sendActions(for: .touchUpInside)
        view.sendActions(for: .touchUpOutside)
        view.sendActions(for: .touchUpInside)
    }

    func testUIDatePicker() {
        let date1 = Date(timeIntervalSince1970: 10)
        let date2 = Date(timeIntervalSince1970: 1000)

        let subject = PassthroughSubject<Date, Never>()

        let view = UIDatePicker()
        subject.bind(to: view)

        subject.send(date1)
        XCTAssertEqual(view.date, date1)

        subject.send(date2)
        XCTAssertEqual(view.date, date2)

        view.reactive.date.expectNext([date2, date1])
        view.date = date1
        view.sendActions(for: .valueChanged)
    }

    func testUIImageView() {
        let image1 = UIImage()
        let image2 = UIImage()

        let subject = PassthroughSubject<UIImage?, Never>()

        let view = UIImageView()
        subject.bind(to: view)

        subject.send(image1)
        XCTAssertEqual(view.image!, image1)

        subject.send(image2)
        XCTAssertEqual(view.image!, image2)

        subject.send(nil)
        XCTAssertEqual(view.image, nil)
    }

    func testUILabel() {
        let subject = PassthroughSubject<String?, Never>()

        let view = UILabel()
        subject.bind(to: view)

        subject.send("a")
        XCTAssertEqual(view.text!, "a")

        subject.send("b")
        XCTAssertEqual(view.text!, "b")

        subject.send(nil)
        XCTAssertEqual(view.text, nil)
    }

    func testUINavigationBar() {
        let subject = PassthroughSubject<UIColor?, Never>()

        let view = UINavigationBar()
        subject.bind(to: view.reactive.barTintColor)

        subject.send(.red)
        XCTAssertEqual(view.barTintColor!, .red)

        subject.send(.blue)
        XCTAssertEqual(view.barTintColor!, .blue)

        subject.send(nil)
        XCTAssertEqual(view.barTintColor, nil)
    }


    func testUINavigationItem() {
        let subject = PassthroughSubject<String?, Never>()

        let view = UINavigationItem()
        subject.bind(to: view.reactive.title)

        subject.send("a")
        XCTAssertEqual(view.title!, "a")

        subject.send("b")
        XCTAssertEqual(view.title!, "b")

        subject.send(nil)
        XCTAssertEqual(view.title, nil)
    }

    func testUIProgressView() {
        let subject = PassthroughSubject<Float, Never>()

        let view = UIProgressView()
        subject.bind(to: view)

        subject.send(0.2)
        XCTAssertEqual(view.progress, 0.2)

        subject.send(0.4)
        XCTAssertEqual(view.progress, 0.4)
    }

    func testUIRefreshControl() {
        let subject = PassthroughSubject<Bool, Never>()

        let view = UIRefreshControl()
        subject.bind(to: view)

        subject.send(true)
        XCTAssertEqual(view.isRefreshing, true)

        subject.send(false)
        XCTAssertEqual(view.isRefreshing, false)

        view.reactive.refreshing.expectNext([false, true])
        view.beginRefreshing()
        view.sendActions(for: .valueChanged)
    }

    func testUISegmentedControl() {
        let subject = PassthroughSubject<Int, Never>()

        let view = UISegmentedControl(items: ["a", "b"])
        subject.bind(to: view)

        subject.send(1)
        XCTAssertEqual(view.selectedSegmentIndex, 1)

        subject.send(0)
        XCTAssertEqual(view.selectedSegmentIndex, 0)

        view.reactive.selectedSegmentIndex.expectNext([0, 1])
        view.selectedSegmentIndex = 1
        view.sendActions(for: .valueChanged)
    }

    func testUISlider() {
        let subject = PassthroughSubject<Float, Never>()

        let view = UISlider()
        subject.bind(to: view)

        subject.send(0.2)
        XCTAssertEqual(view.value, 0.2)

        subject.send(0.4)
        XCTAssertEqual(view.value, 0.4)

        view.reactive.value.expectNext([0.4, 0.6])
        view.value = 0.6
        view.sendActions(for: .valueChanged)
    }

    func testUISwitch() {
        let subject = PassthroughSubject<Bool, Never>()

        let view = UISwitch()
        subject.bind(to: view)

        subject.send(false)
        XCTAssertEqual(view.isOn, false)

        subject.send(true)
        XCTAssertEqual(view.isOn, true)

        view.reactive.isOn.expectNext([true, false])
        view.isOn = false
        view.sendActions(for: .valueChanged)
    }

    func testUITextField() {
        let subject = PassthroughSubject<String?, Never>()

        let view = UITextField()
        subject.bind(to: view)

        subject.send("a")
        XCTAssertEqual(view.text!, "a")

        subject.send("b")
        XCTAssertEqual(view.text!, "b")

        view.reactive.text.expectNext(["b", "c"])
        view.text = "c"
        view.sendActions(for: .allEditingEvents)
    }

    func testUITextView() {
        let subject = PassthroughSubject<String?, Never>()

        let view = UITextView()
        subject.bind(to: view)

        subject.send("a")
        XCTAssertEqual(view.text!, "a")

        subject.send("b")
        XCTAssertEqual(view.text!, "b")

        view.reactive.text.expectNext(["b", "c"])
        view.text = "c"
        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: view)
    }
    
    func testUISearchBar() {
        let subject = PassthroughSubject<String?, Never>()
        
        let view = UISearchBar()
        subject.bind(to: view)
        
        subject.send("a")
        XCTAssertEqual(view.text!, "a")
        
        subject.send("b")
        XCTAssertEqual(view.text!, "b")
        
        view.text = "c"
        view.reactive.text.expectNext(["c"])
    }
}

#endif
