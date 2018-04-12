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

extension TreeOperation {
    /// Merge the given diffs into a single diff.
    public static func merge(diffs: [[TreeOperation]]) -> [TreeOperation] {
        return merge(diffs: diffs, merge: { $0.merging(with: $1) }, makePatch: { $0.patch })
    }
}

private extension TreeOperation {
    /// A function that merges two subsequent collection operations into a diff.
    typealias Merge = (TreeOperation, TreeOperation) -> (existing: TreeOperation?, new: TreeOperation?)

    /// A function that convers a diff into a patch.
    typealias MakePatch = ([TreeOperation]) -> [TreeOperation]

    /// Merge the given diffs into a single diff using the given merge function and the given make patch function.
    static func merge(diffs: [[TreeOperation]], merge: Merge, makePatch: MakePatch) -> [TreeOperation] {
        var diff: [TreeOperation] = []

        for nextDiff in diffs {
            var reminders: [TreeOperation] = []
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
    func transformDiff(_ diff: [TreeOperation], merge: Merge) -> (diff: [TreeOperation], reminder: TreeOperation?) {
        var diff = diff

        var stepsToRemove: [Int] = []
        var newStepUpdated: TreeOperation? = self

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

private extension TreeOperation {
    /// Merge the receiver with the given operation by offseting indices of both operations if needed.
    /// Potentially consumes the receiver, the given operation or both.
    /// For example `I(3).merge(with: D(3))` annihilates both operations resulting in `(nil, nil)`.
    func merging(with other: TreeOperation) -> (existing: TreeOperation?, new: TreeOperation?) {
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
        //        case (.move(let i1from, let i1to), .insert(let i2)):
        //            return [.move(from: i1from, to: i1to), .insert(at: i2)]
        //        case (.move(let i1from, let i1to), .delete(let i2)):
        //            if i1to == i2 {
        //                return [.delete(at: i1from)]
        //            }
        //            return [.move(from: i1from, to: i1to), .insert(at: i2)]
        default:
            return (nil, nil) // TODO:
        }
    }
}
