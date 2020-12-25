//
//  MarkdownLinkTapRecognizer.swift
//  SimpleMarkdownParser Pod
//
//  Helper library: a custom gesture recognizer that can highlight markdown links on labels
//  Stores the last tapped touch area to fetch the link when it activates
//

// A custom tap recognizer that highlights clickable links, fetch the last clicked link easily after that
public class MarkdownLinkTapRecognizer: UIGestureRecognizer {
    
    // --
    // MARK: Members
    // --

    private(set) public var lastTappedTouchArea: MarkdownLinkTouchArea?
    private var touchAreaFinder: MarkdownLinkTouchAreaFinder?
    private var originalAttributedString: NSAttributedString?
    private var highlightedAttributedString: NSAttributedString?
    private var highlightTouchArea: MarkdownLinkTouchArea?
    private var hasHighlight = false
    private let extendLinkRange: CGFloat = 8
    

    // --
    // MARK: Initialization
    // --

    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
    }
    

    // --
    // MARK: Interaction
    // --
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Call super
        if let event = event {
            super.touchesBegan(touches, with: event)
        }
        
        // Make sure there is only 1 touch
        if touches.count > 1 {
            state = .failed
            return
        }
        
        // Set up touch areas if they are not synchronized anymore
        if !touchAreasValid() {
            if let label = view as? UILabel {
                touchAreaFinder = MarkdownLinkTouchAreaFinder(label: label)
                touchAreaFinder?.findTouchAreas()
            } else {
                state = .failed
                return
            }
        }
        
        // Find closest touch area
        var changedLink = false
        if let label = view as? UILabel, let touchPosition = touches.first?.location(in: label) {
            if let touchArea = touchAreaFinder?.getClosestTouchArea(point: touchPosition, extendRange: extendLinkRange) {
                if let replaceAttributedString = getHighlightedAttributedString(touchArea: touchArea) {
                    originalAttributedString = label.attributedText
                    highlightedAttributedString = replaceAttributedString
                    label.attributedText = replaceAttributedString
                    highlightTouchArea = touchArea
                    hasHighlight = true
                    changedLink = true
                }
            }
        }
        
        // Update state to failed when nothing is found
        if !changedLink {
            state = .failed
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Call super
        if let event = event {
            super.touchesMoved(touches, with: event)
        }
        
        // Ignore when already failed or recognized
        if state == .failed || state == .recognized {
            return
        }
        
        // Make sure touch areas are still valid and check if there is only 1 touch
        if touches.count > 1 || !touchAreasValid() {
            state = .failed
            return
        }
        
        // Handle dragging in and out of the touch area
        if let touchArea = highlightTouchArea, let label = view as? UILabel, let touchPosition = touches.first?.location(in: label), originalAttributedString != nil && highlightedAttributedString != nil {
            let insideTouchArea = touchAreaFinder?.inTouchArea(touchArea: touchArea, point: touchPosition, extendRange: extendLinkRange) ?? false
            if insideTouchArea != hasHighlight {
                label.attributedText = insideTouchArea ? highlightedAttributedString : originalAttributedString
                hasHighlight = insideTouchArea
            }
        } else {
            state = .failed
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Call super
        if let event = event {
            super.touchesEnded(touches, with: event)
        }
        
        // Ignore when already failed or recognized
        if state == .failed || state == .recognized {
            return
        }
        
        // Make sure touch areas are still valid and check if there is only 1 touch
        if touches.count > 1 || !touchAreasValid() {
            state = .failed
            return
        }
        
        // Check if still within the touch area and set to recognized
        if let touchArea = highlightTouchArea, let label = view as? UILabel, let touchPosition = touches.first?.location(in: label) {
            state = touchAreaFinder?.inTouchArea(touchArea: touchArea, point: touchPosition, extendRange: extendLinkRange) ?? false ? .recognized : .failed
            if state == .recognized {
                lastTappedTouchArea = touchArea
            }
        } else {
            state = .failed
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        // Call super
        if let event = event, let touches = touches {
            super.touchesCancelled(touches, with: event)
        }
        
        // Reset state
        state = .cancelled
    }
    
    public override func reset() {
        // Call super
        super.reset()
        
        // Remove highlighted link state
        if let label = view as? UILabel, hasHighlight, label.attributedText == highlightedAttributedString {
            label.attributedText = originalAttributedString
        }
        
        // Reset tracking variables
        originalAttributedString = nil
        highlightedAttributedString = nil
        highlightTouchArea = nil
        hasHighlight = false
    }
    

    // --
    // MARK: Helper
    // --
    
    private func touchAreasValid() -> Bool {
        if let touchAreaFinder = touchAreaFinder {
            if touchAreaFinder.label !== view || touchAreaFinder.label == nil {
                return false
            }
            if let label = view as? UILabel {
                if label.attributedText == nil || (label.attributedText != highlightedAttributedString && label.attributedText != originalAttributedString) {
                    return false
                }
            }
            return touchAreaFinder.touchAreasValid(skipAttributedTextCheck: true)
        }
        return false
    }
    
    private func getHighlightedAttributedString(touchArea: MarkdownLinkTouchArea) -> NSAttributedString? {
        if let label = view as? UILabel, let attributedText = label.attributedText {
            let mutableCopy = NSMutableAttributedString(attributedString: attributedText)
            mutableCopy.removeAttribute(NSAttributedString.Key.foregroundColor, range: touchArea.attributeRange)
            mutableCopy.addAttribute(NSAttributedString.Key.foregroundColor, value: touchArea.highlightColor, range: touchArea.attributeRange)
            return mutableCopy
        }
        return nil
    }
   
}
