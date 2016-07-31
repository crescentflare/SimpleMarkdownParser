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
            "Testing a link to [github](https://github.com/crescentflare/SimpleMarkdownParser)."
        ]
        let markdownText = markdownTextArray.joinWithSeparator("\n")
        
        // Markdown tests
        if testHtmlConversion {
            testHtml(markdownText)
        } else {
            if testCustomStyle {
                testCustomAttributedStringConversion(markdownText)
            } else {
                testDefaultAttributedStringConversion(markdownText)
            }
        }
        
        // Add a gesture recognizer to handle tappable links from the markdown
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnLabel(_:)))
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
        let htmlString = SimpleMarkdownConverter.toHtmlString(markdownText)
        let options = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                       NSCharacterEncodingDocumentAttribute: NSNumber(unsignedInteger:NSUTF8StringEncoding)]
        let attributedString = try? NSAttributedString(data: htmlString.dataUsingEncoding(NSUTF8StringEncoding)!, options: options, documentAttributes: nil)
        label.attributedText = attributedString
    }
    
    func testCustomAttributedStringConversion(markdownText: String) {
        let attributedString = SimpleMarkdownConverter.toAttributedString(label.font, markdownText: markdownText, attributedStringGenerator: CustomAttributedStringConversion())
        label.attributedText = attributedString
    }
    
    func testDefaultAttributedStringConversion(markdownText: String) {
        let attributedString = SimpleMarkdownConverter.toAttributedString(label.font, markdownText: markdownText)
        label.attributedText = attributedString
    }

    
    // --
    // MARK: Selector
    // --

    @objc func didTapOnLabel(gesture: UITapGestureRecognizer) {
        if let url: NSURL = gesture.findUrlOnLabel(label) {
            UIApplication.sharedApplication().openURL(url)
        }
    }

}

private class CustomAttributedStringConversion : MarkdownAttributedStringGenerator {
    
    private func applyAttribute(defaultFont: UIFont, attributedString: NSMutableAttributedString, type: MarkdownTagType, weight: Int, start: Int, length: Int, extra: String) {
        switch type {
        case .Paragraph:
            attributedString.addAttribute(NSFontAttributeName, value: defaultFont.fontWithSize(defaultFont.pointSize * CGFloat(weight) * 0.5), range: NSMakeRange(start, length))
            break
        case .Header:
            attributedString.addAttribute(NSFontAttributeName, value: UIFont.init(descriptor: defaultFont.fontDescriptor(), size: defaultFont.pointSize * (2 - CGFloat(weight) * 0.15)), range: NSMakeRange(start, length))
            break
        case .OrderedList, .UnorderedList:
            let bulletParagraph = NSMutableParagraphStyle()
            let tokenTabStop = NSTextTab(textAlignment: .Right, location: 12 + CGFloat(weight - 1) * 10, options: [:])
            let textTabStop = NSTextTab(textAlignment: .Left, location: tokenTabStop.location + 8, options: [:])
            bulletParagraph.tabStops = [ tokenTabStop, textTabStop ]
            bulletParagraph.firstLineHeadIndent = 0
            bulletParagraph.headIndent = textTabStop.location
            attributedString.addAttribute(NSParagraphStyleAttributeName, value: bulletParagraph, range: NSMakeRange(start, length))
            break
        case .TextStyle:
            var deriveFont = defaultFont
            attributedString.enumerateAttributesInRange(NSMakeRange(start, length), options: .LongestEffectiveRangeNotRequired, usingBlock: { (attributes: [String: AnyObject], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if let font = attributes["NSFont"] as? UIFont {
                    deriveFont = font
                }
            })
            var traits: UIFontDescriptorSymbolicTraits = UIFontDescriptorSymbolicTraits()
            traits.insert(defaultFont.fontDescriptor().symbolicTraits)
            if (weight & 1) > 0 {
                traits.insert(.TraitItalic)
            }
            if (weight & 2) > 0 {
                traits.insert(.TraitBold)
            }
            attributedString.addAttribute(NSFontAttributeName, value: UIFont.init(descriptor: deriveFont.fontDescriptor().fontDescriptorWithSymbolicTraits(traits), size: deriveFont.pointSize), range: NSMakeRange(start, length))
            break
        case .AlternativeTextStyle:
            attributedString.addAttribute(NSStrikethroughStyleAttributeName, value: true, range: NSMakeRange(start, length))
            break
        case .Link:
            attributedString.addAttribute(NSLinkAttributeName, value: NSURL(string: extra)!, range: NSMakeRange(start, length))
            break
        default:
            break //No implementation for unknown tags
        }
    }
    
    private func getListToken(type: MarkdownTagType, weight: Int, index: Int) -> String {
        var token = ""
        if type == .OrderedList {
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
