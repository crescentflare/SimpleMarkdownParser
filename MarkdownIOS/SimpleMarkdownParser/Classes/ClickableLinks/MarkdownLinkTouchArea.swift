//
//  MarkdownLinkTouchArea.swift
//  SimpleMarkdownParser Pod
//
//  Library clickable link support: used to store a touch area of a markdown link within a label
//

// A touch area for a clickable link in an attributed string of a label
public class MarkdownLinkTouchArea {
    
    // --
    // MARK: Members
    // --
    
    public let touchRects: [CGRect]
    public let attributeRange: NSRange
    public let highlightColor: UIColor
    public let url: URL
    public let linkText: String
    

    // --
    // MARK: Initialization
    // --

    public init(touchRects: [CGRect], attributeRange: NSRange, highlightColor: UIColor, url: URL, linkText: String) {
        self.touchRects = touchRects
        self.attributeRange = attributeRange
        self.highlightColor = highlightColor
        self.url = url
        self.linkText = linkText
    }

}
