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

#if os(iOS) || os(tvOS)

import UIKit
import ReactiveKit

extension ReactiveExtensions where Base: UIButton {

    public var title: Bond<String?> {
        return bond { $0.setTitle($1, for: .normal) }
    }

    public var tap: SafeSignal<Void> {
        return controlEvents(.touchUpInside)
    }

    public var isSelected: Bond<Bool> {
        return bond { $0.isSelected = $1 }
    }

    public var isHighlighted: Bond<Bool> {
        return bond { $0.isHighlighted = $1 }
    }

    public var backgroundImage: Bond<UIImage?> {
        return bond { $0.setBackgroundImage($1, for: .normal) }
    }

    public var image: Bond<UIImage?> {
        return bond { $0.setImage($1, for: .normal) }
    }
}

#endif
