import XCTest
import UIKit
@testable import MapboxMaps

final class CameraAnimatorsRunnerTests: XCTestCase {
    var mapboxMap: MockMapboxMap!
    var cameraAnimatorsRunner: CameraAnimatorsRunner!

    override func setUp() {
        super.setUp()
        mapboxMap = MockMapboxMap()
        cameraAnimatorsRunner = CameraAnimatorsRunner(
            mapboxMap: mapboxMap)
        cameraAnimatorsRunner.isEnabled = true
    }

    override func tearDown() {
        cameraAnimatorsRunner = nil
        mapboxMap = nil
        super.tearDown()
    }

    func testCameraAnimators() {
        let animators = [MockCameraAnimator].random(
            withLength: 10,
            generator: MockCameraAnimator.init)

        for animator in animators {
            cameraAnimatorsRunner.add(animator)
        }

        XCTAssertEqual(
            Set(cameraAnimatorsRunner.cameraAnimators.map(ObjectIdentifier.init(_:))),
            Set(animators.map(ObjectIdentifier.init(_:))))
    }

    func testUpdateWithAnimationsEnabled() {
        let animator = MockCameraAnimator()
        cameraAnimatorsRunner.add(animator)
        animator.$onCameraAnimatorStatusChanged.send(.started)
        cameraAnimatorsRunner.isEnabled = true

        cameraAnimatorsRunner.update()

        XCTAssertEqual(animator.stopAnimationStub.invocations.count, 0)
        XCTAssertEqual(animator.cancelStub.invocations.count, 0)
        XCTAssertEqual(animator.updateStub.invocations.count, 1)
    }

    func testUpdateWithAnimationsDisabled() {
        let animator = MockCameraAnimator()
        cameraAnimatorsRunner.add(animator)
        animator.$onCameraAnimatorStatusChanged.send(.started)

        cameraAnimatorsRunner.isEnabled = false

        XCTAssertEqual(animator.stopAnimationStub.invocations.count, 1)

        cameraAnimatorsRunner.update()

        XCTAssertEqual(animator.stopAnimationStub.invocations.count, 2)

        XCTAssertEqual(animator.cancelStub.invocations.count, 0)
        XCTAssertEqual(animator.updateStub.invocations.count, 0)
    }

    func testCancelAnimations() {
        let animator = MockCameraAnimator()
        animator.state = .random()
        animator.owner = .random()
        cameraAnimatorsRunner.add(animator)

        cameraAnimatorsRunner.cancelAnimations()

        XCTAssertEqual(animator.stopAnimationStub.invocations.count, 1)
        XCTAssertEqual(animator.cancelStub.invocations.count, 0)
    }

    func testCancelAnimationsWhenDisabled() {
        let animator = MockCameraAnimator()
        animator.state = .random()
        animator.owner = .random()
        cameraAnimatorsRunner.add(animator)

        cameraAnimatorsRunner.isEnabled = false

        XCTAssertEqual(animator.stopAnimationStub.invocations.count, 1)
        XCTAssertEqual(animator.cancelStub.invocations.count, 0)
    }

    func testCancelAnimationsWithEmptyOwnersArray() {
        let animators = [MockCameraAnimator].random(withLength: 10) {
            let animator = MockCameraAnimator()
            animator.state = .random()
            animator.owner = .random()
            return animator
        }

        for animator in animators {
            cameraAnimatorsRunner.add(animator)
        }

        cameraAnimatorsRunner.cancelAnimations(withOwners: [])

        for animator in animators {
            XCTAssertEqual(animator.stopAnimationStub.invocations.count, 0)
            XCTAssertEqual(animator.cancelStub.invocations.count, 0)
        }
    }

    func testCancelAnimationsWithSingleOwner() {
        let owner = AnimationOwner.random()

        let animators = [MockCameraAnimator].random(withLength: 10) {
            let animator = MockCameraAnimator()
            animator.state = .random()
            animator.owner = owner
            return animator
        }

        animators[9].owner = AnimationOwner(rawValue: owner.rawValue + "-other")

        for animator in animators {
            cameraAnimatorsRunner.add(animator)
        }

        cameraAnimatorsRunner.cancelAnimations(withOwners: [owner])

        for animator in animators[0..<9] {
            XCTAssertEqual(animator.stopAnimationStub.invocations.count, 1)
            XCTAssertEqual(animator.cancelStub.invocations.count, 0)
        }

        XCTAssertEqual(animators[9].stopAnimationStub.invocations.count, 0)
        XCTAssertEqual(animators[9].cancelStub.invocations.count, 0)
    }

    func testCancelAnimationsWithMultipleOwners() {
        let owner1 = AnimationOwner.random()
        let owner2 = AnimationOwner.random()

        let animators: [MockCameraAnimator] = .random(withLength: 5) {
            let animator = MockCameraAnimator()
            animator.state = .random()
            animator.owner = owner1
            return animator
        } + .random(withLength: 6) {
            let animator = MockCameraAnimator()
            animator.state = .random()
            animator.owner = owner2
            return animator
        }

        animators[10].owner = AnimationOwner(rawValue: owner1.rawValue + owner2.rawValue + "a")

        for animator in animators {
            cameraAnimatorsRunner.add(animator)
        }

        cameraAnimatorsRunner.cancelAnimations(withOwners: [owner1, owner2])

        for animator in animators[0..<10] {
            XCTAssertEqual(animator.stopAnimationStub.invocations.count, 1)
            XCTAssertEqual(animator.cancelStub.invocations.count, 0)
        }

        XCTAssertEqual(animators[10].stopAnimationStub.invocations.count, 0)
        XCTAssertEqual(animators[10].cancelStub.invocations.count, 0)
    }

    func testCancelAnimationWithSingleOwnerAndSingleType() {
        let owner = AnimationOwner(rawValue: "first-owner")
        let anotherOwner = AnimationOwner(rawValue: "second-owner")
        let thirdOwner = AnimationOwner(rawValue: "third-owner")

        let makeAnimator = { (owner: AnimationOwner, animationType: AnimationType) -> MockCameraAnimator in
            let decelerationAnimator = MockCameraAnimator()
            decelerationAnimator.state = .random()
            decelerationAnimator.animationType = animationType
            decelerationAnimator.owner = owner
            return decelerationAnimator
        }

        let decelerationAnimator = makeAnimator(owner, .deceleration)
        let decelerationAnimatorOtherOwner = makeAnimator(anotherOwner, .deceleration)
        let unspecifiedAnimator = makeAnimator(owner, .unspecified)
        let unspecifiedAnimatorThirdOwner = makeAnimator(thirdOwner, .unspecified)

        [decelerationAnimator, decelerationAnimatorOtherOwner, unspecifiedAnimator, unspecifiedAnimatorThirdOwner]
            .forEach(cameraAnimatorsRunner.add)

        cameraAnimatorsRunner.cancelAnimations(withOwners: [owner], andTypes: [.deceleration])

        XCTAssertEqual(decelerationAnimator.stopAnimationStub.invocations.count, 1)
        XCTAssertEqual(decelerationAnimatorOtherOwner.stopAnimationStub.invocations.count, 0)
        XCTAssertEqual(unspecifiedAnimator.stopAnimationStub.invocations.count, 0)
        XCTAssertEqual(unspecifiedAnimatorThirdOwner.stopAnimationStub.invocations.count, 0)
    }

    func testCancelAnimationWithMultipleOwnerAndMultipleType() {
        let owner = AnimationOwner(rawValue: "first-owner")
        let anotherOwner = AnimationOwner(rawValue: "second-owner")
        let thirdOwner = AnimationOwner(rawValue: "third-owner")

        let makeAnimator = { (owner: AnimationOwner, animationType: AnimationType) -> MockCameraAnimator in
            let decelerationAnimator = MockCameraAnimator()
            decelerationAnimator.state = .random()
            decelerationAnimator.animationType = animationType
            decelerationAnimator.owner = owner
            return decelerationAnimator
        }

        let decelerationAnimator = makeAnimator(owner, .deceleration)
        let decelerationAnimatorOtherOwner = makeAnimator(anotherOwner, .deceleration)
        let unspecifiedAnimator = makeAnimator(owner, .unspecified)
        let unspecifiedAnimatorThirdOwner = makeAnimator(thirdOwner, .unspecified)

        [decelerationAnimator, decelerationAnimatorOtherOwner, unspecifiedAnimator, unspecifiedAnimatorThirdOwner]
            .forEach(cameraAnimatorsRunner.add)

        cameraAnimatorsRunner.cancelAnimations(withOwners: [owner, anotherOwner], andTypes: [.deceleration, .unspecified])

        XCTAssertEqual(decelerationAnimator.stopAnimationStub.invocations.count, 1)
        XCTAssertEqual(decelerationAnimatorOtherOwner.stopAnimationStub.invocations.count, 1)
        XCTAssertEqual(unspecifiedAnimator.stopAnimationStub.invocations.count, 1)
        XCTAssertEqual(unspecifiedAnimatorThirdOwner.stopAnimationStub.invocations.count, 0)
    }

    func testCameraAnimatorStatus() {
        let animator1 = MockCameraAnimator()
        let animator2 = MockCameraAnimator()

        cameraAnimatorsRunner.add(animator1)
        cameraAnimatorsRunner.add(animator2)

        // stopping before starting should have no effect
        animator1.$onCameraAnimatorStatusChanged.send(.stopped(reason: .cancelled))
        XCTAssertEqual(mapboxMap.beginAnimationStub.invocations.count, 0)
        XCTAssertEqual(mapboxMap.endAnimationStub.invocations.count, 0)

        // start once
        animator1.$onCameraAnimatorStatusChanged.send(.started)
        XCTAssertEqual(mapboxMap.beginAnimationStub.invocations.count, 1)
        XCTAssertEqual(mapboxMap.endAnimationStub.invocations.count, 0)

        // start twice
        animator1.$onCameraAnimatorStatusChanged.send(.started)
        XCTAssertEqual(mapboxMap.beginAnimationStub.invocations.count, 1)
        XCTAssertEqual(mapboxMap.endAnimationStub.invocations.count, 0)

        // start a second
        animator2.$onCameraAnimatorStatusChanged.send(.started)
        XCTAssertEqual(mapboxMap.beginAnimationStub.invocations.count, 2)
        XCTAssertEqual(mapboxMap.endAnimationStub.invocations.count, 0)

        // end the first
        animator1.$onCameraAnimatorStatusChanged.send(.stopped(reason: .finished))
        XCTAssertEqual(mapboxMap.beginAnimationStub.invocations.count, 2)
        XCTAssertEqual(mapboxMap.endAnimationStub.invocations.count, 1)

        // end the first again
        animator1.$onCameraAnimatorStatusChanged.send(.stopped(reason: .finished))
        XCTAssertEqual(mapboxMap.beginAnimationStub.invocations.count, 2)
        XCTAssertEqual(mapboxMap.endAnimationStub.invocations.count, 1)

        // end the second
        animator2.$onCameraAnimatorStatusChanged.send(.stopped(reason: .finished))
        XCTAssertEqual(mapboxMap.beginAnimationStub.invocations.count, 2)
        XCTAssertEqual(mapboxMap.endAnimationStub.invocations.count, 2)
    }

    func testCameraAnimatorPaused() {
        var mockCameraAnimator = MockCameraAnimator()
        cameraAnimatorsRunner.isEnabled = true
        cameraAnimatorsRunner.add(mockCameraAnimator)

        mockCameraAnimator.$onCameraAnimatorStatusChanged.send(.started)
        XCTAssertEqual(mapboxMap.beginAnimationStub.invocations.count, 1)

        mockCameraAnimator.$onCameraAnimatorStatusChanged.send(.paused)
        XCTAssertEqual(mapboxMap.endAnimationStub.invocations.count, 1)
    }

    func testAddWithAnimationsEnabled() {
        cameraAnimatorsRunner.isEnabled = true

        let animator = MockCameraAnimator()

        cameraAnimatorsRunner.add(animator)

        XCTAssertEqual(animator.stopAnimationStub.invocations.count, 0)
    }

    func testAddWithAnimationsDisabled() {
        cameraAnimatorsRunner.isEnabled = false

        let animator = MockCameraAnimator()

        cameraAnimatorsRunner.add(animator)

        XCTAssertEqual(animator.stopAnimationStub.invocations.count, 1)
    }

    func testCameraAnimatorStatusObserver() {
        let mockCameraAnimator = MockCameraAnimator()
        cameraAnimatorsRunner.isEnabled = true
        cameraAnimatorsRunner.add(mockCameraAnimator)

        let observedExpectation = self.expectation(description: "animator status observer should be notified")
        observedExpectation.expectedFulfillmentCount = 2
        observedExpectation.assertForOverFulfill = true
        let observer1 = CameraAnimatorStatusObserver(owners: []) { animator in
            XCTAssertIdentical(mockCameraAnimator, animator)
            observedExpectation.fulfill()
        } onStopped: { animator, isCancelled in
            XCTAssertIdentical(mockCameraAnimator, animator)
            XCTAssertFalse(isCancelled)
            observedExpectation.fulfill()
        }
        cameraAnimatorsRunner.add(cameraAnimatorStatusObserver: observer1)

        let notObservedExpectation = self.expectation(description: "animator status observer should not be notified about animator of different owner")
        notObservedExpectation.isInverted = true
        let observer2 = CameraAnimatorStatusObserver(owners: [.cameraAnimationsManager]) { _ in
            notObservedExpectation.fulfill()
        } onStopped: { _, _ in
            notObservedExpectation.fulfill()
        }
        cameraAnimatorsRunner.add(cameraAnimatorStatusObserver: observer2)

        mockCameraAnimator.$onCameraAnimatorStatusChanged.send(.started)
        mockCameraAnimator.$onCameraAnimatorStatusChanged.send(.stopped(reason: .finished))

        waitForExpectations(timeout: 0.3)
    }
}
