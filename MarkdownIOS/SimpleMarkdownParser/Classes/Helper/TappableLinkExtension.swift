//
//  TappableLinkExtension.swift
//  SimpleMarkdownParser Pod
//
//  Helper library: extends the gesture recognizer to be able to find links within the markdown (so they can be opened)
//

public extension UITapGestureRecognizer {
    
    func findUrl(onLabel: UILabel) -> URL? {
        // Fetch attributed text and apply label font entirely, then set up text storage
        let attributedText = NSMutableAttributedString(attributedString: onLabel.attributedText!)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
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
        
        // Determine offset multiplier based on label alignment
        var offsetMultiplier: CGFloat = 0
        if onLabel.textAlignment == .center {
            offsetMultiplier = 0.5
        } else if onLabel.textAlignment == .right {
            offsetMultiplier = 1
        }
        
        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: onLabel)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * offsetMultiplier - textBoundingBox.origin.x,
                                          y: (labelSize.height - textBoundingBox.size.height) * offsetMultiplier - textBoundingBox.origin.y);
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y: locationOfTouchInLabel.y - textContainerOffset.y);
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        // Try to find a matching URL and return the result
        var url: URL? = nil
        onLabel.attributedText!.enumerateAttributes(in: NSMakeRange(indexOfCharacter, 1), options: .longestEffectiveRangeNotRequired, using: { (attributes: [NSAttributedString.Key: Any], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
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
    
}
