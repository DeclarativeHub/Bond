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

public protocol PatchOperationProtocol {
    associatedtype Element
    associatedtype Index: Comparable
    var asPatchOperation: PatchOperation<Element, Index> { get }
}

/// Described the change made to a collection. An array of collection operations is called "diff".
public enum PatchOperation<Element, Index: Comparable> : PatchOperationProtocol, CustomDebugStringConvertible {

    case insert(Element, at: Index)
    case delete(at: Index)
    case update(at: Index, newElement: Element)
    case move(from: Index, to: Index)

    public var asPatchOperation: PatchOperation<Element, Index> {
        return self
    }

    public var asValuelessPatch: ValuelessPatchOperation<Index> {
        switch self {
        case .insert(_, let at):
            return .insert(at: at)
        case .delete(let at):
            return .delete(at: at)
        case .update(let at, _):
            return .update(at: at)
        case .move(let from, let to):
            return .move(from: from, to: to)
        }
    }


    public var debugDescription: String {
        switch self {
        case .insert(let element, let at):
            return "I(\(element), at: \(at))"
        case .delete(let at):
            return "D(at: \(at))"
        case .update(let at, let newElement):
            return "U(at: \(at), with: \(newElement))"
        case .move(let from, let to):
            return "M(from: \(from), to: \(to))"
        }
    }
}


extension CollectionDiff {

    /// - complexity: O(I + D + U * (I + D + M) + M * (I + D + U + M)) where I, D, U and M are numbers of inserts, deletes, updates and moves respectively.
    public func patch<C: Collection, S: IndexStrider>(to: C, using strider: S) -> [PatchOperation<C.Element, Index>] where S.Index == Index, C.Index == Index {
        let updatedAfterPatch = updatesAfterPatch(using: strider)
        let u: [PatchOperation<C.Element, Index>] = updates.enumerated().map { .update(at: $0.element, newElement: to[updatedAfterPatch[$0.offset]]) }
        let d: [PatchOperation<C.Element, Index>] = deletes.map { .delete(at: $0) }
        let m: [PatchOperation<C.Element, Index>] = adjustedMoves(using: strider).map { .move(from: $0.from, to: $0.to) }
        let i: [PatchOperation<C.Element, Index>] = inserts.map { .insert(to[$0], at: $0) }
        return u + d + m + i
    }

    /// - complexity: O(I + D + U + M * (I + D + U + M)) where I, D, U and M are numbers of inserts, deletes, updates and moves respectively.
    public func patch<S: IndexStrider>(using strider: S) -> [ValuelessPatchOperation<Index>] where S.Index == Index {
        let u: [ValuelessPatchOperation<Index>] = updates.map { .update(at: $0) }
        let d: [ValuelessPatchOperation<Index>] = deletes.map { .delete(at: $0) }
        let m: [ValuelessPatchOperation<Index>] = adjustedMoves(using: strider).map { .move(from: $0, to: $1) }
        let i: [ValuelessPatchOperation<Index>] = inserts.map { .insert(at: $0) }
        return u + d + m + i
    }

    private func adjustedMoves<S: IndexStrider>(using strider: S) -> [(from: Index, to: Index)] where S.Index == Index {
        var moves = self.moves

        guard !moves.isEmpty else {
            return []
        }

        for delete in deletes {
            for i in 0..<moves.count {
                if moves[i].from > delete {
                    moves[i].from = strider.shift(moves[i].from, by: -1)
                }
            }
        }

        for insert in inserts.reversed() {
            for i in 0..<moves.count {
                if moves[i].to >= insert {
                    moves[i].to = strider.shift(moves[i].to, by: -1)
                }
            }
        }

        for i in 0..<moves.count {
            let from = moves[i].from
            for j in i+1..<moves.count {
                let subsequentFrom = moves[j].from
                if subsequentFrom >= from {
                    moves[j].from = strider.shift(subsequentFrom, by: -1)
                }
            }
        }

        for i in (0..<moves.count).reversed() {
            let to = moves[i].to
            for j in 0..<i {
                let priorTo = moves[j].to
                if priorTo > to {
                    moves[j].to = strider.shift(priorTo, by: -1)
                }
            }
        }

        for i in 0..<moves.count {
            for j in (i+1..<moves.count).reversed() {
                if moves[j].from < moves[i].to {
                    moves[i].to = strider.shift(moves[i].to, by: 1)
                } else {
                    moves[j].from = strider.shift(moves[j].from, by: 1)
                }
            }
        }

        return moves
    }

    private func updatesAfterPatch<S: IndexStrider>(using strider: S) -> [Index] where S.Index == Index {
        var updatedAfterPatch = updates

        guard !updatedAfterPatch.isEmpty else {
            return []
        }

        for delete in (deletes + moves.map { $0.from }).sorted(by: >) {
            for i in 0..<updatedAfterPatch.count {
                if updatedAfterPatch[i] > delete {
                    updatedAfterPatch[i] = strider.shift(updatedAfterPatch[i], by: -1)
                }
            }
        }
        for insert in (inserts + moves.map { $0.to }).sorted(by: <) {
            for i in 0..<updatedAfterPatch.count {
                if updatedAfterPatch[i] >= insert {
                    updatedAfterPatch[i] = strider.shift(updatedAfterPatch[i], by: 1)
                }
            }
        }

        return updatedAfterPatch
    }
}

