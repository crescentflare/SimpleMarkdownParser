//
//  TappableLinkExtension.swift
//  SimpleMarkdownParser Pod
//
//  Helper library: extends the gesture recognizer to be able to find links within the markdown (so they can be opened)
//

public extension UITapGestureRecognizer {
    
    func findUrl(onLabel: UILabel) -> URL? {
        if let attributedText = onLabel.attributedText {
            // Fetch attributed text and apply label font entirely, then set up text storage
            let attributedText = NSMutableAttributedString(attributedString: attributedText)
            let textStorage = NSTextStorage(attributedString: attributedText)
            if onLabel.textAlignment != .left {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = onLabel.textAlignment
                textStorage.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedText.length))
            }
            
            // Create instances of NSLayoutManager and NSTextContainer, then link them
            let labelSize = onLabel.bounds.size
            let layoutManager = NSLayoutManager()
            let textContainer = NSTextContainer(size: labelSize)
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            
            // Configure textContainer
            textContainer.lineFragmentPadding = 0.0
            textContainer.lineBreakMode = onLabel.lineBreakMode
            textContainer.maximumNumberOfLines = onLabel.numberOfLines
            
            // Find the tapped character location and compare it to the specified range
            let locationOfTouchInLabel = self.location(in: onLabel)
            let textBoundingBox = layoutManager.usedRect(for: textContainer)
            let textVerticalOffset = (labelSize.height - textBoundingBox.size.height) * 0.5
            let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x, y: locationOfTouchInLabel.y - textVerticalOffset)
            let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            
            // Safeguard for detecting links outside of the actual character (2 points extra margin is added on purpose)
            let extraCheckMargin: CGFloat = 2
            let glyphsForIndex = layoutManager.glyphRange(forCharacterRange: NSMakeRange(indexOfCharacter, 1), actualCharacterRange: nil)
            let characterBounds = layoutManager.boundingRect(forGlyphRange: glyphsForIndex, in: textContainer)
            if locationOfTouchInTextContainer.y < characterBounds.minY - extraCheckMargin || locationOfTouchInTextContainer.y >= characterBounds.maxY + extraCheckMargin {
                return nil
            }
            if locationOfTouchInTextContainer.x < characterBounds.minX - extraCheckMargin || locationOfTouchInTextContainer.x >= characterBounds.maxX + extraCheckMargin {
                return nil
            }
            
            // Try to find a matching URL and return the result
            var url: URL? = nil
            attributedText.enumerateAttributes(in: NSMakeRange(indexOfCharacter, 1), options: .longestEffectiveRangeNotRequired, using: { (attributes: [NSAttributedString.Key: Any], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                for (key, value) in attributes {
                    if key.rawValue == NSClickableTextAttributeName || key == .link {
                        if value is URL {
                            url = value as? URL
                            break
                        }
                    }
                }
            })
            return url
        }
        return nil
    }
    
}
