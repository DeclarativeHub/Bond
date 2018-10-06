//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

import Foundation

public extension IndexPath {

    public func isAffectedByDeletionOrInsertion(at index: IndexPath) -> Bool {
        assert(index.count > 0)
        assert(self.count > 0)
        guard index.count <= self.count else { return false }
        let testLevel = index.count - 1
        if index.prefix(testLevel) == self.prefix(testLevel) {
            return index[testLevel] <= self[testLevel]
        } else {
            return false
        }
    }

    public func shifted(by: Int, atLevelOf other: IndexPath) -> IndexPath {
        assert(self.count > 0)
        assert(other.count > 0)
        let level = other.count - 1
        guard level < self.count else { return self }
        if by == -1 {
            return self.advanced(by: -1, atLevel: level)
        } else if by == 1 {
            return self.advanced(by: 1, atLevel: level)
        } else {
            fatalError()
        }
    }

    public func advanced(by offset: Int, atLevel level: Int) -> IndexPath {
        var copy = self
        copy[level] += offset
        return copy
    }

    public func isAncestor(of other: IndexPath) -> Bool {
        guard self.count < other.count else { return false }
        return self == other.prefix(self.count)
    }

    public func replacingAncestor(_ ancestor: IndexPath, with newAncestor: IndexPath) -> IndexPath {
        return newAncestor + dropFirst(ancestor.count)
    }
}
