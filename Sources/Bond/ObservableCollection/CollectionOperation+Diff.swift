//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 DeclarativeHub/Bond
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

extension CollectionOperation {

    /// Merge the given diffs into a single diff.
    public static func merge(diffs: [[CollectionOperation<Index>]]) -> [CollectionOperation<Index>] {
        return merge(diffs: diffs, merge: { $0.merging(with: $1) }, makePatch: { $0 })
    }
}

extension CollectionOperation where Index: Strideable {

    /// Merge the given diffs into a single diff.
    public static func merge(diffs: [[CollectionOperation<Index>]]) -> [CollectionOperation<Index>] {
        return merge(diffs: diffs, merge: { $0.merging(with: $1) }, makePatch: { $0.patch } )
    }
}

extension CollectionOperation {

    /// A function that merges two subsequent collection operations into a diff.
    typealias Merge = (CollectionOperation<Index>, CollectionOperation<Index>) -> (existing: CollectionOperation<Index>?, new: CollectionOperation<Index>?)

    /// A function that convers a diff into a patch.
    typealias MakePatch = ([CollectionOperation<Index>]) -> [CollectionOperation<Index>]

    /// Merge the given diffs into a single diff using the given merge function and the given make patch function.
    static func merge(diffs: [[CollectionOperation<Index>]], merge: Merge, makePatch: MakePatch) -> [CollectionOperation<Index>] {
        var diff: [CollectionOperation<Index>] = []

        for nextDiff in diffs {
            var reminders: [CollectionOperation<Index>] = []
            for step in makePatch(nextDiff) {
                let result = step.transformDiff(diff, merge: merge)
                diff = result.diff
                if let reminder = result.reminder {
                    reminders.append(reminder)
                }
            }
            diff += reminders
        }

        return diff
    }

    /// Transform the given diff by the receiver by merging each diff operation with the receiver using the given merge function.
    /// - Returns: Diff that can be merged by the recived by appending the updated receiver (reminder) if not consumed.
    func transformDiff(_ diff: [CollectionOperation<Index>], merge: Merge) -> (diff: [CollectionOperation<Index>], reminder: CollectionOperation<Index>?) {
        var diff = diff

        var stepsToRemove: [Int] = []
        var newStepUpdated: CollectionOperation<Index>? = self

        for index in (0..<diff.count).reversed() {
            let step = diff[index]
            if let updated = merge(step, self).existing {
                diff[index] = updated
            } else {
                stepsToRemove.append(index)
            }
            if let _newStepUpdated = newStepUpdated {
                newStepUpdated = merge(step, _newStepUpdated).new
            }
        }

        for index in stepsToRemove.reversed() {
            diff.remove(at: index)
        }

        return (diff, newStepUpdated)
    }
}

extension CollectionOperation {

    /// Merge the receiver with the given operation.
    /// Potentially consumes the receiver, the given operation or both.
    /// For example `I(3).merge(with: D(3))` annihilates both operations resulting in `(nil, nil)`.
    func merging(with other: CollectionOperation<Index>) -> (existing: CollectionOperation<Index>?, new: CollectionOperation<Index>?) {
        switch (self, other) {
        // Insert:
        case (.insert(let i1), .delete(let i2)) where i1 == i2:
            return (nil, nil)
        case (.insert(let i1), .update(let i2)) where i1 == i2:
            return (self, nil)
        case (.insert, _):
            return (self, other)
        // Delete:
        case (.delete, _):
            return (self, other)
        // Update:
        case (.update(let i1), .delete(let i2)) where i1 == i2:
            return (nil, other)
        case (.update(let i1), .update(let i2)) where i1 == i2:
            return (self, nil)
        case (.update, _):
            return (self, other)
        // Move:
        case (.move, _):
            return (self, other)
        }
    }
}

extension CollectionOperation where Index: Strideable {

    /// Merge the receiver with the given operation by offseting indices of both operations if needed.
    /// Potentially consumes the receiver, the given operation or both.
    /// For example `I(3).merge(with: D(3))` annihilates both operations resulting in `(nil, nil)`.
    func merging(with other: CollectionOperation<Index>) -> (existing: CollectionOperation<Index>?, new: CollectionOperation<Index>?) {
        switch (self, other) {
        // Insert:
        case (.insert(let i1), .insert(let i2)):
            if i1 < i2 {
                return (.insert(at: i1), .insert(at: i2))
            } else {
                return (.insert(at: i1.advanced(by: 1)), .insert(at: i2))
            }
        case (.insert(let i1), .delete(let i2)):
            if i1 < i2 {
                return (.insert(at: i1), .delete(at: i2.advanced(by: -1)))
            } else if i1 == i2 {
                return (nil, nil)
            } else {
                return (.insert(at: i1.advanced(by: -1)), .delete(at: i2))
            }
        case (.insert(let i1), .update(let i2)):
            if i1 < i2 {
                return (.insert(at: i1), .update(at: i2.advanced(by: -1)))
            } else if i1 == i2 {
                return (.insert(at: i1), nil)
            } else {
                return (.insert(at: i1), .update(at: i2))
            }
        case (.insert(let i1), .move(let i2from, let i2to)):
            if i1 == i2from {
                return (.insert(at: i2to), nil)
            } else if i1 < i2from {
                if i1 < i2to {
                    return (.insert(at: i1), .move(from: i2from.advanced(by: -1), to: i2to))
                } else {
                    return (.insert(at: i1.advanced(by: 1)), .move(from: i2from.advanced(by: -1), to: i2to))
                }
            } else {
                if i1 < i2to {
                    return (.insert(at: i1.advanced(by: -1)), .move(from: i2from, to: i2to))
                } else if i1 == i2to {
                    return (.insert(at: i1), .move(from: i2from, to: i2to.advanced(by: -1)))
                } else {
                    return (.insert(at: i1), .move(from: i2from, to: i2to))
                }
            }
        // Delete:
        case (.delete(let i1), .insert(let i2)):
            return (.delete(at: i1), .insert(at: i2))
        case (.delete(let i1), .delete(let i2)):
            if i1 <= i2 {
                return (.delete(at: i1), .delete(at: i2.advanced(by: 1)))
            } else {
                return (.delete(at: i1), .delete(at: i2))
            }
        case (.delete(let i1), .update(let i2)):
            if i1 <= i2 {
                return (.delete(at: i1), .update(at: i2.advanced(by: 1)))
            } else {
                return (.delete(at: i1), .update(at: i2))
            }
        case (.delete(let i1), .move(let i2from, let i2to)):
            if i1 <= i2from {
                return (.delete(at: i1), .move(from: i2from.advanced(by: 1), to: i2to))
            } else {
                return (.delete(at: i1), .move(from: i2from, to: i2to))
            }
        // Update:
        case (.update(let i1), .insert(let i2)):
            return (.update(at: i1), .insert(at: i2))
        case (.update(let i1), .delete(let i2)):
            if i1 < i2 {
                return (.update(at: i1), .delete(at: i2))
            } else if i1 == i2 {
                return (nil, .delete(at: i2))
            } else {
                return (.update(at: i1), .delete(at: i2))
            }
        case (.update(let i1), .update(let i2)):
            if i1 < i2 {
                return (.update(at: i1), .update(at: i2))
            } else if i1 == i2 {
                return (.update(at: i1), nil)
            } else {
                return (.update(at: i1), .update(at: i2))
            }
        case (.update(let i1), .move(let i2from, let i2to)):
            if i1 == i2from {
                return (.delete(at: i1), .insert(at: i2to))
            } else {
                return (.update(at: i1), .move(from: i2from, to: i2to))
            }
        // Move:
        case (.move(let i1from, let i1to), .insert(let i2)):
            if i2 <= i1to {
                return (.move(from: i1from, to: i1to.advanced(by: 1)), .insert(at: i2))
            } else {
                return (.move(from: i1from, to: i1to), .insert(at: i2))
            }
        case (.move(let i1from, let i1to), .delete(let i2)):
            if i1to == i2 {
                return (nil, .delete(at: i1from))
            } else if i1to < i2 {
                if i1from < i2 {
                    return (.move(from: i1from, to: i1to), .delete(at: i2))
                } else {
                    return (.move(from: i1from, to: i1to), .delete(at: i2.advanced(by: -1)))
                }
            } else /* i1to > i2 */ {
                if i1from <= i2 {
                    return (.move(from: i1from, to: i1to.advanced(by: -1)), .delete(at: i2.advanced(by: 1)))
                } else {
                    return (.move(from: i1from, to: i1to.advanced(by: -1)), .delete(at: i2))
                }
            }
        case (.move(let i1from, let i1to), .update(let i2)):
            if i1to == i2 {
                return (.delete(at: i1from), .insert(at: i2))
            } else {
                return (.move(from: i1from, to: i1to), .update(at: i2))
            }
        case (.move(let i1from, let i1to), .move(let i2from, let i2to)):
            if i1to == i2from && i2to == i1from {
                return (nil, nil)
            } else if i1to == i2from && i2to != i1from {
                return (.move(from: i1from, to: i2to), nil)
            } else {
                // Treat incoming move as delete + insert
                let d1 = merging(with: .delete(at: i2from))
                let d2 = d1.existing!.merging(with: .insert(at: i2to))
                switch (d2.existing!, d1.new!, d2.new!) {
                case (.move(let i1from, let i1to), .delete(let i2from), .insert(let i2to)):
                    return (.move(from: i1from, to: i1to), .move(from: i2from, to: i2to))
                default:
                    fatalError("Impossible code path.")
                }
            }
        }
    }
}
