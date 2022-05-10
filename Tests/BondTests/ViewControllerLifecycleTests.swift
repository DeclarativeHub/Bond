#if os(iOS) || os(tvOS)

import XCTest
import ReactiveKit
@testable import Bond

class ViewControllerLifecycleTests: XCTestCase {

    func testViewDidLoad() {
        let sut = UIViewController()
        let accumulator = Subscribers.Accumulator<LifecycleEvent, Never>()
        sut.reactive.lifecycleEvents.subscribe(accumulator)
        sut.viewDidLoad()
        XCTAssertEqual(accumulator.values, [.viewDidLoad])
    }

    func testViewWillAppear() {
        let sut = UIViewController()
        let accumulator = Subscribers.Accumulator<LifecycleEvent, Never>()
        sut.reactive.lifecycleEvents.subscribe(accumulator)
        sut.viewWillAppear(false)
        sut.viewWillAppear(true)
        XCTAssertEqual(
            accumulator.values,
            [
                .viewWillAppear(false),
                .viewWillAppear(true)
            ]
        )
    }

    func testViewDidAppear() {
        let sut = UIViewController()
        let accumulator = Subscribers.Accumulator<LifecycleEvent, Never>()
        sut.reactive.lifecycleEvents.subscribe(accumulator)
        sut.viewDidAppear(false)
        sut.viewDidAppear(true)
        XCTAssertEqual(
            accumulator.values,
            [
                .viewDidAppear(false),
                .viewDidAppear(true)
            ]
        )
    }

    func testViewWillDisappear() {
        let sut = UIViewController()
        let accumulator = Subscribers.Accumulator<LifecycleEvent, Never>()
        sut.reactive.lifecycleEvents.subscribe(accumulator)
        sut.viewWillDisappear(false)
        sut.viewWillDisappear(true)
        XCTAssertEqual(
            accumulator.values,
            [
                .viewWillDisappear(false),
                .viewWillDisappear(true)
            ]
        )
    }

    func testViewDidDisappear() {
        let sut = UIViewController()
        let accumulator = Subscribers.Accumulator<LifecycleEvent, Never>()
        sut.reactive.lifecycleEvents.subscribe(accumulator)
        sut.viewDidDisappear(false)
        sut.viewDidDisappear(true)
        XCTAssertEqual(
            accumulator.values,
            [
                .viewDidDisappear(false),
                .viewDidDisappear(true)
            ]
        )
    }

    func testViewWillLayoutSubviews() {
        let sut = UIViewController()
        let accumulator = Subscribers.Accumulator<LifecycleEvent, Never>()
        sut.reactive.lifecycleEvents.subscribe(accumulator)
        sut.viewWillLayoutSubviews()
        XCTAssertEqual(
            accumulator.values,
            [
                .viewWillLayoutSubviews
            ]
        )
    }

    func testViewDidLayoutSubviews() {
        let sut = UIViewController()
        let accumulator = Subscribers.Accumulator<LifecycleEvent, Never>()
        sut.reactive.lifecycleEvents.subscribe(accumulator)
        sut.viewDidLayoutSubviews()
        XCTAssertEqual(
            accumulator.values,
            [
                .viewDidLayoutSubviews
            ]
        )
    }

    func testCustomViewController() {

        class TestViewController: UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
            }

            override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
            }

            override func viewWillLayoutSubviews() {
                super.viewWillLayoutSubviews()
            }

            override func viewDidLayoutSubviews() {
                super.viewDidLayoutSubviews()
            }

            override func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
            }

            override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
            }

            override func viewDidDisappear(_ animated: Bool) {
                super.viewDidDisappear(animated)
            }
        }

        let sut = TestViewController()
        let accumulator = Subscribers.Accumulator<LifecycleEvent, Never>()
        sut.reactive.lifecycleEvents.subscribe(accumulator)
        sut.viewDidLoad()
        sut.viewWillAppear(false)
        sut.viewWillLayoutSubviews()
        sut.viewDidLayoutSubviews()
        sut.viewDidAppear(false)
        XCTAssertEqual(
            accumulator.values,
            [
                .viewDidLoad,
                .viewWillAppear(false),
                .viewWillLayoutSubviews,
                .viewDidLayoutSubviews,
                .viewDidAppear(false)
            ]
        )
    }
}

#endif
