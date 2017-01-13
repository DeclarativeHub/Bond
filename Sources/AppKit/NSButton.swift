//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Tony Arnold (@tonyarnold)
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

import AppKit
import ReactiveKit

public extension ReactiveExtensions where Base: NSButton {

  public var title: DynamicSubject<String> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.title), ofType: String.self).eraseType(),
      get: { $0.title },
      set: { $0.title = $1 }
    )
  }

  public var alternateTitle: DynamicSubject<String> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.alternateTitle), ofType: String.self).eraseType(),
      get: { $0.alternateTitle },
      set: { $0.alternateTitle = $1 }
    )
  }

  public var image: DynamicSubject<NSImage?> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.image), ofType: Optional<NSImage>.self).eraseType(),
      get: { $0.image },
      set: { $0.image = $1 }
    )
  }

  public var alternateImage: DynamicSubject<NSImage?> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.alternateImage), ofType: Optional<NSImage>.self).eraseType(),
      get: { $0.alternateImage },
      set: { $0.alternateImage = $1 }
    )
  }

  public var state: DynamicSubject<Int> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.state), ofType: Int.self).eraseType(),
      get: { $0.state },
      set: { $0.state = $1 }
    )
  }

  public var imagePosition: DynamicSubject<NSCellImagePosition> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.imagePosition), ofType: NSCellImagePosition.self).eraseType(),
      get: { $0.imagePosition },
      set: { $0.imagePosition = $1 }
    )
  }

  public var imageScaling: DynamicSubject<NSImageScaling> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.imageScaling), ofType: NSImageScaling.self).eraseType(),
      get: { $0.imageScaling },
      set: { $0.imageScaling = $1 }
    )
  }

  @available(macOS 10.12, *)
  public var imageHugsTitle: DynamicSubject<Bool> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.imageHugsTitle), ofType: Bool.self).eraseType(),
      get: { $0.imageHugsTitle },
      set: { $0.imageHugsTitle = $1 }
    )
  }

  public var isBordered: DynamicSubject<Bool> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.isBordered), ofType: Bool.self).eraseType(),
      get: { $0.isBordered },
      set: { $0.isBordered = $1 }
    )
  }

  public var isTransparent: DynamicSubject<Bool> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.isTransparent), ofType: Bool.self).eraseType(),
      get: { $0.isTransparent },
      set: { $0.isTransparent = $1 }
    )
  }

  public var keyEquivalent: DynamicSubject<String> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.keyEquivalent), ofType: String.self).eraseType(),
      get: { $0.keyEquivalent },
      set: { $0.keyEquivalent = $1 }
    )
  }

  public var keyEquivalentModifierMask: DynamicSubject<NSEventModifierFlags> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.keyEquivalentModifierMask), ofType: NSEventModifierFlags.self).eraseType(),
      get: { $0.keyEquivalentModifierMask },
      set: { $0.keyEquivalentModifierMask = $1 }
    )
  }

  @available(macOS 10.10.3, *)
  public var isSpringLoaded: DynamicSubject<Bool> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.isSpringLoaded), ofType: Bool.self).eraseType(),
      get: { $0.isSpringLoaded },
      set: { $0.isSpringLoaded = $1 }
    )
  }

  @available(macOS 10.10.3, *)
  public var maxAcceleratorLevel: DynamicSubject<Int> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.maxAcceleratorLevel), ofType: Int.self).eraseType(),
      get: { $0.maxAcceleratorLevel },
      set: { $0.maxAcceleratorLevel = $1 }
    )
  }

  @available(macOS 10.12.2, *)
  public var bezelColor: DynamicSubject<NSColor?> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.bezelColor), ofType: Optional<NSColor>.self).eraseType(),
      get: { $0.bezelColor },
      set: { $0.bezelColor = $1 }
    )
  }

  public var attributedTitle: DynamicSubject<NSAttributedString> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.attributedTitle), ofType: NSAttributedString.self).eraseType(),
      get: { $0.attributedTitle },
      set: { $0.attributedTitle = $1 }
    )
  }

  public var attributedAlternateTitle: DynamicSubject<NSAttributedString> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.attributedAlternateTitle), ofType: NSAttributedString.self).eraseType(),
      get: { $0.attributedAlternateTitle },
      set: { $0.attributedAlternateTitle = $1 }
    )
  }

  public var bezelStyle: DynamicSubject<NSBezelStyle> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.bezelStyle), ofType: Optional<NSBezelStyle>.self).eraseType(),
      get: { $0.bezelStyle },
      set: { $0.bezelStyle = $1 }
    )
  }

  public var allowsMixedState: DynamicSubject<Bool> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.allowsMixedState), ofType: Optional<Bool>.self).eraseType(),
      get: { $0.allowsMixedState },
      set: { $0.allowsMixedState = $1 }
    )
  }

  public var showsBorderOnlyWhileMouseInside: DynamicSubject<Bool> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.showsBorderOnlyWhileMouseInside), ofType: Optional<Bool>.self).eraseType(),
      get: { $0.showsBorderOnlyWhileMouseInside },
      set: { $0.showsBorderOnlyWhileMouseInside = $1 }
    )
  }

  public var sound: DynamicSubject<NSSound?> {
    return dynamicSubject(
      signal: keyPath(#keyPath(NSButton.sound), ofType: Optional<NSSound>.self).eraseType(),
      get: { $0.sound },
      set: { $0.sound = $1 }
    )
  }
}

