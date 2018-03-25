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

        SafeSignal.just(UIColor.red).bind(to: view.reactive.backgroundColor)
        XCTAssertEqual(view.backgroundColor!, UIColor.red)

        SafeSignal.just(0.3).bind(to: view.reactive.alpha)
        XCTAssertEqual(view.alpha, 0.3)

        SafeSignal.just(true).bind(to: view.reactive.isHidden)
        XCTAssertEqual(view.isHidden, true)

        SafeSignal.just(true).bind(to: view.reactive.isUserInteractionEnabled)
        XCTAssertEqual(view.isUserInteractionEnabled, true)

        SafeSignal.just(UIColor.red).bind(to: view.reactive.tintColor)
        XCTAssertEqual(view.tintColor, UIColor.red)
    }

    func testUIActivityIndicatorView() {
        let subject = PublishSubject1<Bool>()

        let view = UIActivityIndicatorView()
        subject.bind(to: view.reactive.isAnimating)

        XCTAssertEqual(view.isAnimating, false)

        subject.next(true)
        XCTAssertEqual(view.isAnimating, true)

        subject.next(false)
        XCTAssertEqual(view.isAnimating, false)
    }

    func testUIBarItem() {
        let view = UIBarButtonItem()

        SafeSignal.just("test").bind(to: view.reactive.title)
        XCTAssertEqual(view.title!, "test")

        let image = UIImage()
        SafeSignal.just(image).bind(to: view.reactive.image)
        XCTAssertEqual(view.image!, image)

        SafeSignal.just(true).bind(to: view.reactive.isEnabled)
        XCTAssertEqual(view.isEnabled, true)
        SafeSignal.just(false).bind(to: view.reactive.isEnabled)
        XCTAssertEqual(view.isEnabled, false)

        view.reactive.tap.expectNext([(), ()])
        view.reactive.tap.expectNext([(), ()]) // second observer
        _ = view.target!.perform(view.action!)
        _ = view.target!.perform(view.action!)
    }

    func testUIButton() {
        let view = UIButton()

        SafeSignal.just("test").bind(to: view.reactive.title)
        XCTAssertEqual(view.titleLabel?.text, "test")

        SafeSignal.just(true).bind(to: view.reactive.isSelected)
        XCTAssertEqual(view.isSelected, true)
        SafeSignal.just(false).bind(to: view.reactive.isSelected)
        XCTAssertEqual(view.isSelected, false)

        SafeSignal.just(true).bind(to: view.reactive.isHighlighted)
        XCTAssertEqual(view.isHighlighted, true)
        SafeSignal.just(false).bind(to: view.reactive.isHighlighted)
        XCTAssertEqual(view.isHighlighted, false)

        let image = UIImage()
        let image2 = UIImage()

        SafeSignal.just(image).bind(to: view.reactive.backgroundImage)
        XCTAssertEqual(view.backgroundImage(for: .normal), image)

        SafeSignal.just(image2).bind(to: view.reactive.image)
        XCTAssertEqual(view.image(for: .normal), image2)

        view.reactive.tap.expectNext([(), ()])
        view.sendActions(for: .touchUpInside)
        view.sendActions(for: .touchUpInside)
        view.sendActions(for: .touchUpOutside)
    }

    func testUIControl() {
        let view = UIControl()

        SafeSignal.just(true).bind(to: view.reactive.isEnabled)
        XCTAssertEqual(view.isEnabled, true)
        SafeSignal.just(false).bind(to: view.reactive.isEnabled)
        XCTAssertEqual(view.isEnabled, false)

        view.reactive.controlEvents(UIControlEvents.touchUpInside).expectNext([(), ()])
        view.sendActions(for: .touchUpInside)
        view.sendActions(for: .touchUpOutside)
        view.sendActions(for: .touchUpInside)
    }

    func testUIDatePicker() {
        let date1 = Date(timeIntervalSince1970: 10)
        let date2 = Date(timeIntervalSince1970: 1000)

        let subject = PublishSubject1<Date>()

        let view = UIDatePicker()
        subject.bind(to: view)

        subject.next(date1)
        XCTAssertEqual(view.date, date1)

        subject.next(date2)
        XCTAssertEqual(view.date, date2)

        view.reactive.date.expectNext([date2, date1])
        view.date = date1
        view.sendActions(for: .valueChanged)
    }

    func testUIImageView() {
        let image1 = UIImage()
        let image2 = UIImage()

        let subject = PublishSubject1<UIImage?>()

        let view = UIImageView()
        subject.bind(to: view)

        subject.next(image1)
        XCTAssertEqual(view.image!, image1)

        subject.next(image2)
        XCTAssertEqual(view.image!, image2)

        subject.next(nil)
        XCTAssertEqual(view.image, nil)
    }

    func testUILabel() {
        let subject = PublishSubject1<String?>()

        let view = UILabel()
        subject.bind(to: view)

        subject.next("a")
        XCTAssertEqual(view.text!, "a")

        subject.next("b")
        XCTAssertEqual(view.text!, "b")

        subject.next(nil)
        XCTAssertEqual(view.text, nil)
    }

    func testUINavigationBar() {
        let subject = PublishSubject1<UIColor?>()

        let view = UINavigationBar()
        subject.bind(to: view.reactive.barTintColor)

        subject.next(.red)
        XCTAssertEqual(view.barTintColor!, .red)

        subject.next(.blue)
        XCTAssertEqual(view.barTintColor!, .blue)

        subject.next(nil)
        XCTAssertEqual(view.barTintColor, nil)
    }


    func testUINavigationItem() {
        let subject = PublishSubject1<String?>()

        let view = UINavigationItem()
        subject.bind(to: view.reactive.title)

        subject.next("a")
        XCTAssertEqual(view.title!, "a")

        subject.next("b")
        XCTAssertEqual(view.title!, "b")

        subject.next(nil)
        XCTAssertEqual(view.title, nil)
    }

    func testUIProgressView() {
        let subject = PublishSubject1<Float>()

        let view = UIProgressView()
        subject.bind(to: view)

        subject.next(0.2)
        XCTAssertEqual(view.progress, 0.2)

        subject.next(0.4)
        XCTAssertEqual(view.progress, 0.4)
    }

    func testUIRefreshControl() {
        let subject = PublishSubject1<Bool>()

        let view = UIRefreshControl()
        subject.bind(to: view)

        subject.next(true)
        XCTAssertEqual(view.isRefreshing, true)

        subject.next(false)
        XCTAssertEqual(view.isRefreshing, false)

        view.reactive.refreshing.expectNext([false, true])
        view.beginRefreshing()
        view.sendActions(for: .valueChanged)
    }

    func testUISegmentedControl() {
        let subject = PublishSubject1<Int>()

        let view = UISegmentedControl(items: ["a", "b"])
        subject.bind(to: view)

        subject.next(1)
        XCTAssertEqual(view.selectedSegmentIndex, 1)

        subject.next(0)
        XCTAssertEqual(view.selectedSegmentIndex, 0)

        view.reactive.selectedSegmentIndex.expectNext([0, 1])
        view.selectedSegmentIndex = 1
        view.sendActions(for: .valueChanged)
    }

    func testUISlider() {
        let subject = PublishSubject1<Float>()

        let view = UISlider()
        subject.bind(to: view)

        subject.next(0.2)
        XCTAssertEqual(view.value, 0.2)

        subject.next(0.4)
        XCTAssertEqual(view.value, 0.4)

        view.reactive.value.expectNext([0.4, 0.6])
        view.value = 0.6
        view.sendActions(for: .valueChanged)
    }

    func testUISwitch() {
        let subject = PublishSubject1<Bool>()

        let view = UISwitch()
        subject.bind(to: view)

        subject.next(false)
        XCTAssertEqual(view.isOn, false)

        subject.next(true)
        XCTAssertEqual(view.isOn, true)

        view.reactive.isOn.expectNext([true, false])
        view.isOn = false
        view.sendActions(for: .valueChanged)
    }

    func testUITextField() {
        let subject = PublishSubject1<String?>()

        let view = UITextField()
        subject.bind(to: view)

        subject.next("a")
        XCTAssertEqual(view.text!, "a")

        subject.next("b")
        XCTAssertEqual(view.text!, "b")

        view.reactive.text.expectNext(["b", "c"])
        view.text = "c"
        view.sendActions(for: .allEditingEvents)
    }

    func testUITextView() {
        let subject = PublishSubject1<String?>()

        let view = UITextView()
        subject.bind(to: view)

        subject.next("a")
        XCTAssertEqual(view.text!, "a")

        subject.next("b")
        XCTAssertEqual(view.text!, "b")

        view.reactive.text.expectNext(["b", "c"])
        view.text = "c"
        NotificationCenter.default.post(name: NSNotification.Name.UITextViewTextDidChange, object: view)
    }
    
    func testUISearchBar() {
        let subject = PublishSubject1<String?>()
        
        let view = UISearchBar()
        subject.bind(to: view)
        
        subject.next("a")
        XCTAssertEqual(view.text!, "a")
        
        subject.next("b")
        XCTAssertEqual(view.text!, "b")
        
        view.text = "c"
        view.reactive.text.expectNext(["c"])
    }
}

#endif
