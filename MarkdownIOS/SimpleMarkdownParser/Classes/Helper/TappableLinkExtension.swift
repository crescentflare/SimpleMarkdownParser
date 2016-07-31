//
//  TappableLinkExtension.swift
//  SimpleMarkdownParser Pod
//
//  Helper library: extends the gesture recognizer to be able to find links within the markdown (so they can be opened)
//

public extension UITapGestureRecognizer {
    
    func findUrlOnLabel(label: UILabel) -> NSURL? {
        // Fetch attributed text and apply label font entirely, then set up text storage
        let attributedText = NSMutableAttributedString(attributedString: label.attributedText!)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
        // Create instances of NSLayoutManager and NSTextContainer, then link them
        let labelSize = label.bounds.size
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: labelSize)
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        
        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.locationInView(label)
        let textBoundingBox = layoutManager.usedRectForTextContainer(textContainer)
        let textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                              (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
        let locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
                                                         locationOfTouchInLabel.y - textContainerOffset.y);
        let indexOfCharacter = layoutManager.characterIndexForPoint(locationOfTouchInTextContainer, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        // Try to find a matching URL and return the result
        var url: NSURL? = nil
        label.attributedText!.enumerateAttributesInRange(NSMakeRange(indexOfCharacter, 1), options: .LongestEffectiveRangeNotRequired, usingBlock: { (attributes: [String: AnyObject], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            for (key, value) in attributes {
                if key == NSLinkAttributeName {
                    if value is NSURL {
                        url = value as? NSURL
                        break
                    }
                }
            }
        })
        return url
    }
    
}
