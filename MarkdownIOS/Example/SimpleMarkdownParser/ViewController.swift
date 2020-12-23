//
//  ViewController.swift
//  SimpleMarkdownParser Example
//
//  A simple screen which shows formatted markdown
//

import UIKit
import SimpleMarkdownParser

class ViewController: UIViewController {

    // --
    // MARK: Define test to display
    // --
    
    let testHtmlConversion = false
    let testCustomStyle = false

    
    // --
    // MARK: View components
    // --
    
    @IBOutlet var label: UILabel!

    
    // --
    // MARK: Lifecycle
    // --

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up markdown text
        let markdownTextArray: [String] = [
            "# First chapter",
            "This text can be either __bold__ or *italics*.",
            "A combination is ***also possible***.",
            "### Small heading",
            "With a \\*single\\* line of ~~strike through~~ text.",
            "",
            "A new paragraph starts here.",
            "",
            "1. First item",
            "2. Second item",
            "  * First nested bullet item",
            "  * Second nested bullet item with a longer set of text to make it wrap around to a new line",
            "",
            "Testing a link to [github](https://github.com/crescentflare/SimpleMarkdownParser \"SimpleMarkdownParser\")."
        ]
        let markdownText = markdownTextArray.joined(separator: "\n")
        
        // Markdown tests
        if testHtmlConversion {
            testHtml(markdownText: markdownText)
        } else {
            if testCustomStyle {
                testCustomAttributedStringConversion(markdownText: markdownText)
            } else {
                testDefaultAttributedStringConversion(markdownText: markdownText)
            }
        }
        
        // Add a gesture recognizer to handle tappable links from the markdown
        let gestureRecognizer = MarkdownLinkTapRecognizer(target: self, action: #selector(didTapOnLabelLink(_:)))
        label.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewDidLayoutSubviews() {
        let newWidth = view.frame.size.width - 16
        if label.preferredMaxLayoutWidth != newWidth {
            label.preferredMaxLayoutWidth = newWidth
            view.setNeedsLayout()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    // --
    // MARK: Markdown tests
    // --
    
    func testHtml(markdownText: String) {
        let htmlString = SimpleMarkdownConverter.toHtmlString(fromMarkdownText: markdownText)
        if let htmlData = htmlString.data(using: String.Encoding.utf8) {
            let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html,
                           NSAttributedString.DocumentReadingOptionKey(rawValue: "CharacterEncoding"): NSNumber(value: String.Encoding.utf8.rawValue)] as [NSAttributedString.DocumentReadingOptionKey : Any]
            let attributedString = try? NSAttributedString(data: htmlData, options: options, documentAttributes: nil)
            label.attributedText = attributedString
        }
    }
    
    func testCustomAttributedStringConversion(markdownText: String) {
        let attributedString = SimpleMarkdownConverter.toAttributedString(defaultFont: label.font, markdownText: markdownText, attributedStringGenerator: CustomAttributedStringConversion())
        label.attributedText = attributedString
    }
    
    func testDefaultAttributedStringConversion(markdownText: String) {
        let attributedString = SimpleMarkdownConverter.toAttributedString(defaultFont: label.font, markdownText: markdownText)
        label.attributedText = attributedString
    }

    
    // --
    // MARK: Selector
    // --

    @objc func didTapOnLabelLink(_ gesture: MarkdownLinkTapRecognizer) {
        if let url = gesture.lastTappedTouchArea?.url {
            UIApplication.shared.openURL(url)
        }
    }

}

private class CustomAttributedStringConversion : MarkdownAttributedStringGenerator {
    
    fileprivate func applyAttribute(defaultFont: UIFont, attributedString: NSMutableAttributedString, type: MarkdownTagType, weight: Int, start: Int, length: Int, extra: String) {
        switch type {
        case .header:
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.init(descriptor: defaultFont.fontDescriptor, size: defaultFont.pointSize * (2 - CGFloat(weight) * 0.15)), range: NSMakeRange(start, length))
        case .orderedListItem, .unorderedListItem:
            let bulletParagraph = NSMutableParagraphStyle()
            let tokenTabStop = NSTextTab(textAlignment: .right, location: 12 + CGFloat(weight - 1) * 10, options: [:])
            let textTabStop = NSTextTab(textAlignment: .left, location: tokenTabStop.location + 8, options: [:])
            bulletParagraph.tabStops = [ tokenTabStop, textTabStop ]
            bulletParagraph.firstLineHeadIndent = 0
            bulletParagraph.headIndent = textTabStop.location
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: bulletParagraph, range: NSMakeRange(start, length))
        case .textStyle:
            var deriveFont = defaultFont
            attributedString.enumerateAttributes(in: NSMakeRange(start, length), options: .longestEffectiveRangeNotRequired, using: { (attributes: [NSAttributedString.Key: Any], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if let font = attributes[NSAttributedString.Key.font] as? UIFont {
                    deriveFont = font
                }
            })
            var traits: UIFontDescriptor.SymbolicTraits = UIFontDescriptor.SymbolicTraits()
            traits.insert(defaultFont.fontDescriptor.symbolicTraits)
            if (weight & 1) > 0 {
                traits.insert(.traitItalic)
            }
            if (weight & 2) > 0 {
                traits.insert(.traitBold)
            }
            if let descriptor = deriveFont.fontDescriptor.withSymbolicTraits(traits) {
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.init(descriptor: descriptor, size: deriveFont.pointSize), range: NSMakeRange(start, length))
            }
        case .alternativeTextStyle:
            attributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: true, range: NSMakeRange(start, length))
        case .link:
            if let url = URL(string: extra) {
                attributedString.addAttribute(NSAttributedString.Key(rawValue: NSClickableTextAttributeName), value: url, range: NSMakeRange(start, length))
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.purple, range: NSMakeRange(start, length))
                attributedString.addAttribute(NSAttributedString.Key(rawValue: NSHighlightColorAttributeName), value: UIColor.purple.withAlphaComponent(0.5), range: NSMakeRange(start, length))
            }
        default:
            break //No implementation for unknown tags
        }
    }
    
    open func applySectionSpacerAttribute(defaultFont: UIFont, attributedString: NSMutableAttributedString, previousSectionType: MarkdownTagType, previousSectionWeight: Int, nextSectionType: MarkdownTagType, nextSectionWeight: Int, start: Int, length: Int) {
        let spacing: CGFloat = nextSectionType == .header && previousSectionType != .header ? 20 : 12
        attributedString.addAttribute(NSAttributedString.Key.font, value: defaultFont.withSize(spacing), range: NSMakeRange(start, length))
    }
    
    fileprivate func getListToken(fromType: MarkdownTagType, weight: Int, index: Int) -> String {
        var token = ""
        if fromType == .orderedListItem {
            for _ in 0..<index {
                token += "i"
            }
            token += "."
        } else {
            for _ in 0..<weight {
                token += ">"
            }
        }
        return "\t\(token)\t"
    }
    
}
