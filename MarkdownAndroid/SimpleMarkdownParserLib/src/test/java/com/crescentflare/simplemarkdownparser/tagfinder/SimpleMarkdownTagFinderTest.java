package com.crescentflare.simplemarkdownparser.tagfinder;

import com.crescentflare.simplemarkdownparser.symbolfinder.MarkdownSymbol;
import com.crescentflare.simplemarkdownparser.symbolfinder.SimpleMarkdownSymbolFinder;
import com.crescentflare.simplemarkdownparser.symbolfinder.SimpleMarkdownSymbolFinderJava;

import junit.framework.Assert;

import org.junit.Test;

import java.util.List;

/**
 * Tag finder test: find tags in markdown text
 */
public class SimpleMarkdownTagFinderTest {

    // --
    // Tests
    // --

    @Test
    public void testFindTagsNewlines() {
        String[] markdownTextLines = new String[] {
            "",
            "",
            "Text",
            "",
            "",
            "",
            "Another",
            ""
        };
        WrappedMarkdownTag[] expectedTags = new WrappedMarkdownTag[] {
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Another"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Another")
        };
        assertTags(markdownTextLines, expectedTags);
    }

    @Test
    public void testFindTagsHeaders() {
        String[] markdownTextLines = new String[] {
            "Some text",
            "",
            "#First header",
            "Additional text",
            "And more",
            "",
            "  ##   Last header",
            "",
            "Final text"
        };
        WrappedMarkdownTag[] expectedTags = new WrappedMarkdownTag[] {
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Some text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Some text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Header, 1, "First header"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "#First header"),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Additional text\nAnd more"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Additional text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "And more"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Header, 2, "Last header"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "##   Last header"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Final text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Final text")
        };
        assertTags(markdownTextLines, expectedTags);
    }

    @Test
    public void testFindTagsSections() {
        String[] markdownTextLines = new String[] {
            "",
            "",
            "  #A strange indented header",
            "Another piece of text",
            "  ",
            "Text with a space separator to separate paragraph",
            "",
            "Another paragraph",
            "  # Sudden header",
            "Text",
            "",
            "* Bullet item",
            "* Second item",
            "  With some text",
            "",
            "New paragraph"
        };
        WrappedMarkdownTag[] expectedTags = new WrappedMarkdownTag[] {
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Header, 1, "A strange indented header"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "#A strange indented header"),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Another piece of text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Another piece of text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Text with a space separator to separate paragraph"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Text with a space separator to separate paragraph"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Another paragraph"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Another paragraph"),
            new WrappedMarkdownTag(MarkdownTag.Type.Header, 1, "Sudden header"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "# Sudden header"),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.List, "* Bullet item\n* Second item\n  With some text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "* Bullet item"),
            new WrappedMarkdownTag(MarkdownTag.Type.UnorderedListItem, 1, "Bullet item"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "* Second item"),
            new WrappedMarkdownTag(MarkdownTag.Type.UnorderedListItem, 1, "Second item\n  With some text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "With some text"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "New paragraph"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "New paragraph")
        };
        assertTags(markdownTextLines, expectedTags);
    }

    @Test
    public void testFindTagsStyling() {
        String[] markdownTextLines = new String[] {
            "Some text **before** the captions",
            "# Caption 1",
            "Some lines of _styled and **double styled** text_ which should be formatted correctly.",
            "Also new lines should work properly.",
            "### Caption 3",
            "The caption above is a bit smaller. Below add more lines to start a new \\*paragraph\\*.",
            "",
            "New paragraph here with ~~strike through text in **bold**~~.",
            "",
            "+ A bullet list",
            "- Second bullet item",
            "  * A nested item",
            "* Third bullet item",
            "  1. Nested first item",
            "  2. Nested second item",
            "And some text afterwards with a [link](https://www.github.com)."
        };
        WrappedMarkdownTag[] expectedTags = new WrappedMarkdownTag[] {
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Some text **before** the captions"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Some text **before** the captions"),
            new WrappedMarkdownTag(MarkdownTag.Type.TextStyle, 2, "before"),
            new WrappedMarkdownTag(MarkdownTag.Type.Header, 1, "Caption 1"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "# Caption 1"),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "Some lines of _styled and **double styled** text_ which should be formatted correctly.\nAlso new lines should work properly."),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Some lines of _styled and **double styled** text_ which should be formatted correctly."),
            new WrappedMarkdownTag(MarkdownTag.Type.TextStyle, 1, "styled and **double styled** text"),
            new WrappedMarkdownTag(MarkdownTag.Type.TextStyle, 2, "double styled"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "Also new lines should work properly."),
            new WrappedMarkdownTag(MarkdownTag.Type.Header, 3, "Caption 3"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "### Caption 3"),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "The caption above is a bit smaller. Below add more lines to start a new *paragraph*.", "", "**"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "The caption above is a bit smaller. Below add more lines to start a new *paragraph*.", "", "**"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "New paragraph here with ~~strike through text in **bold**~~."),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "New paragraph here with ~~strike through text in **bold**~~."),
            new WrappedMarkdownTag(MarkdownTag.Type.AlternativeTextStyle, 2, "strike through text in **bold**"),
            new WrappedMarkdownTag(MarkdownTag.Type.TextStyle, 2, "bold"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line),
            new WrappedMarkdownTag(MarkdownTag.Type.List, "+ A bullet list\n- Second bullet item\n  * A nested item\n* Third bullet item\n  1. Nested first item\n  2. Nested second item"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "+ A bullet list"),
            new WrappedMarkdownTag(MarkdownTag.Type.UnorderedListItem, 1, "A bullet list"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "- Second bullet item"),
            new WrappedMarkdownTag(MarkdownTag.Type.UnorderedListItem, 1, "Second bullet item"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "* A nested item"),
            new WrappedMarkdownTag(MarkdownTag.Type.UnorderedListItem, 2, "A nested item"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "* Third bullet item"),
            new WrappedMarkdownTag(MarkdownTag.Type.UnorderedListItem, 1, "Third bullet item"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "1. Nested first item"),
            new WrappedMarkdownTag(MarkdownTag.Type.OrderedListItem, 2, "Nested first item"),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "2. Nested second item"),
            new WrappedMarkdownTag(MarkdownTag.Type.OrderedListItem, 2, "Nested second item"),
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "And some text afterwards with a [link](https://www.github.com)."),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "And some text afterwards with a [link](https://www.github.com)."),
            new WrappedMarkdownTag(MarkdownTag.Type.Link, "link", "https://www.github.com")
        };
        assertTags(markdownTextLines, expectedTags);
    }

    @Test
    public void testFindTagsEdgeCases() {
        String[] markdownTextLines = new String[] {
            "A strange ***combination** tag*."
        };
        WrappedMarkdownTag[] expectedTags = new WrappedMarkdownTag[] {
            new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, "A strange ***combination** tag*."),
            new WrappedMarkdownTag(MarkdownTag.Type.Line, "A strange ***combination** tag*."),
            new WrappedMarkdownTag(MarkdownTag.Type.TextStyle, 2, "*combination")
        };
        assertTags(markdownTextLines, expectedTags);
    }

    @Test
    public void testEmptyString() {
        assertTags(new String[0], new WrappedMarkdownTag[0]);
    }


    // --
    // Helpers
    // --

    private void assertTags(String[] markdownTextLines, WrappedMarkdownTag[] expectedTags) {
        // Find symbols
        SimpleMarkdownSymbolFinder symbolFinder = new SimpleMarkdownSymbolFinderJava();
        String markdownText = joinWithNewlines(markdownTextLines);
        symbolFinder.scanText(markdownText);

        // Find tags and compare
        SimpleMarkdownTagFinder tagFinder = new SimpleMarkdownTagFinder();
        List<MarkdownTag> foundTags = tagFinder.findTags(markdownText, symbolFinder.getSymbolStorage().symbols);
        for (int i = 0; i < foundTags.size() && i < expectedTags.length; i++) {
            Assert.assertEquals(expectedTags[i], new WrappedMarkdownTag(markdownText, foundTags.get(i)));
        }
        Assert.assertEquals(expectedTags.length, foundTags.size());
    }

    private String joinWithNewlines(String[] stringArray) {
        StringBuilder joinedText = new StringBuilder();
        boolean firstLine = true;
        for (String string : stringArray) {
            if (!firstLine) {
                joinedText.append("\n");
            }
            joinedText.append(string);
            firstLine = false;
        }
        return joinedText.toString();
    }


    // --
    // Helper class to simplify comparing tags
    // --

    private static class WrappedMarkdownTag {
        private final MarkdownTag.Type type;
        private final int weight;
        private final String text;
        private final String extra;
        private final String escapedCharacters;

        public WrappedMarkdownTag(MarkdownTag.Type type) {
            this(type, 0, "", "", "");
        }

        public WrappedMarkdownTag(MarkdownTag.Type type, String text) {
            this(type, 0, text, "", "");
        }

        public WrappedMarkdownTag(MarkdownTag.Type type, int weight, String text) {
            this(type, weight, text, "", "");
        }

        public WrappedMarkdownTag(MarkdownTag.Type type, String text, String extra) {
            this(type, 0, text, extra, "");
        }

        public WrappedMarkdownTag(MarkdownTag.Type type, int weight, String text, String extra) {
            this(type, weight, text, extra, "");
        }

        public WrappedMarkdownTag(MarkdownTag.Type type, String text, String extra, String escapedCharacters) {
            this(type, 0, text, extra, escapedCharacters);
        }

        public WrappedMarkdownTag(MarkdownTag.Type type, int weight, String text, String extra, String escapedCharacters) {
            this.type = type;
            this.weight = weight;
            this.text = text;
            this.extra = extra;
            this.escapedCharacters = escapedCharacters;
        }

        public WrappedMarkdownTag(String markdownText, MarkdownTag tag) {
            int textOffset = tag.startText;
            StringBuilder applyText = new StringBuilder(markdownText.substring(tag.startText, tag.endText));
            StringBuilder applyEscapedCharacters = new StringBuilder();
            String applyExtra = "";
            if (tag.startExtra >= 0 && tag.endExtra >= tag.startExtra) {
                applyExtra = markdownText.substring(tag.startExtra, tag.endExtra);
            }
            for (MarkdownSymbol escapeSymbol : tag.escapeSymbols) {
                applyEscapedCharacters.append(markdownText.charAt(escapeSymbol.endPosition));
            }
            for (int i = tag.escapeSymbols.size() - 1; i >= 0; i--) {
                MarkdownSymbol escapeSymbol = tag.escapeSymbols.get(i);
                if (escapeSymbol.startPosition - textOffset < applyText.length()) {
                    applyText.delete(escapeSymbol.startPosition - textOffset, escapeSymbol.startPosition - textOffset + 1);
                }
            }
            this.type = tag.type;
            this.weight = tag.weight;
            this.text = applyText.toString();
            this.extra = applyExtra;
            this.escapedCharacters = applyEscapedCharacters.toString();
        }

        @Override
        public boolean equals(Object o) {
            // Object check
            if (this == o) {
                return true;
            } else if (o == null || getClass() != o.getClass()) {
                return false;
            }

            // Variable check
            WrappedMarkdownTag that = (WrappedMarkdownTag)o;
            if (type != that.type) {
                return false;
            }
            if (weight != that.weight) {
                return false;
            }
            if (!escapedCharacters.equals(that.escapedCharacters)) {
                return false;
            }
            if (!extra.equals(that.extra)) {
                return false;
            }
            return text.equals(that.text);
        }

        @Override
        public String toString() {
            return "WrappedMarkdownTag{" +
                    "type=" + type +
                    ", weight=" + weight +
                    ", text='" + text + '\'' +
                    ", extra='" + extra + '\'' +
                    ", escapedCharacters='" + escapedCharacters + '\'' +
                    '}';
        }
    }
}
