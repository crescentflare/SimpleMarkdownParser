package com.crescentflare.simplemarkdownparser.symbolfinder;

import junit.framework.Assert;

import org.junit.Test;

import java.util.List;

/**
 * Symbol finder test: find symbols in markdown text
 */
public class SimpleMarkdownSymbolFinderTest {

    // --
    // Tests
    // --

    @Test
    public void testFindTextBlockSymbols() {
        String[] markdownTextLines = new String[] {
            "",
            "",
            "Line",
            "",
            "",
            "",
            "  Another line ",
            ""
        };
        WrappedMarkdownSymbol[] expectedSymbols = new WrappedMarkdownSymbol[] {
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 0, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 1, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "Line", 2, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 2, 4),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 3, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 4, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 5, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "Another line", 6, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 6, 15)
        };
        assertSymbols(markdownTextLines, expectedSymbols);
    }

    @Test
    public void testFindHeaderSymbols() {
        String[] markdownTextLines = new String[] {
            "#Nospacedheader",
            "## Corrected header",
            "### Wrapped header  ###",
            "Some header # token in between",
            "  ##   Extra spacey header "
        };
        WrappedMarkdownSymbol[] expectedSymbols = new WrappedMarkdownSymbol[] {
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Header, "#", 0, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "#Nospacedheader", 0, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 0, 15),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Header, "##", 1, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "## Corrected header", 1, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 1, 19),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Header, "###", 2, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "### Wrapped header  ###", 2, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Header, "###", 2, 20),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 2, 23),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "Some header # token in between", 3, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Header, "#", 3, 12),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 3, 30),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Header, "##", 4, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "##   Extra spacey header", 4, 2)
        };
        assertSymbols(markdownTextLines, expectedSymbols);
    }

    @Test
    public void testFindTextStyleSymbols() {
        String[] markdownTextLines = new String[] {
            "Simple text with _italics_",
            "  **bold** and _italics_ ",
            "*nested __text style__*",
            "Mixed ~~strike **and~~ bold**",
            "Some _ incomplete *** text style ~~~ markers"
        };
        WrappedMarkdownSymbol[] expectedSymbols = new WrappedMarkdownSymbol[] {
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "Simple text with _italics_", 0, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.SecondTextStyle, "_", 0, 17),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.SecondTextStyle, "_", 0, 25),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 0, 26),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.FirstTextStyle, "**", 1, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "**bold** and _italics_", 1, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.FirstTextStyle, "**", 1, 8),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.SecondTextStyle, "_", 1, 15),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.SecondTextStyle, "_", 1, 23),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 1, 25),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.FirstTextStyle, "*", 2, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "*nested __text style__*", 2, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.SecondTextStyle, "__", 2, 8),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.SecondTextStyle, "__", 2, 20),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.FirstTextStyle, "*", 2, 22),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 2, 23),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "Mixed ~~strike **and~~ bold**", 3, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.ThirdTextStyle, "~~", 3, 6),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.FirstTextStyle, "**", 3, 15),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.ThirdTextStyle, "~~", 3, 20),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.FirstTextStyle, "**", 3, 27),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 3, 29),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "Some _ incomplete *** text style ~~~ markers", 4, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.SecondTextStyle, "_", 4, 5),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.FirstTextStyle, "***", 4, 18),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.ThirdTextStyle, "~~~", 4, 33)
        };
        assertSymbols(markdownTextLines, expectedSymbols);
    }

    @Test
    public void testFindListSymbols() {
        String[] markdownTextLines = new String[] {
            "* First bullet point",
            "- Second bullet point",
            "  + Indented item",
            "1. Ordered item",
            "  1. Nested numbered item",
            "  2. Second one",
            "",
            "1 No list symbol"
        };
        WrappedMarkdownSymbol[] expectedSymbols = new WrappedMarkdownSymbol[] {
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.UnorderedListItem, "*", 0, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "* First bullet point", 0, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 0, 20),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.UnorderedListItem, "-", 1, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "- Second bullet point", 1, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 1, 21),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.UnorderedListItem, "+", 2, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "+ Indented item", 2, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 2, 17),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.OrderedListItem, "1.", 3, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "1. Ordered item", 3, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 3, 15),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.OrderedListItem, "1.", 4, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "1. Nested numbered item", 4, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 4, 25),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.OrderedListItem, "2.", 5, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "2. Second one", 5, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 5, 15),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 6, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "1 No list symbol", 7, 0)
        };
        assertSymbols(markdownTextLines, expectedSymbols);
    }

    @Test
    public void testFindLinkSymbols() {
        String[] markdownTextLines = new String[] {
            "Simple link: [https://www.github.com]",
            "[Named link](https://www.github.com/crescentflare)",
            "Quote link: [open Google](https://www.google.com \"Google's homepage\")",
            "Some [ random ) link tokens (]]"
        };
        WrappedMarkdownSymbol[] expectedSymbols = new WrappedMarkdownSymbol[] {
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "Simple link: [https://www.github.com]", 0, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.OpenLink, "[", 0, 13),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.CloseLink, "]", 0, 36),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 0, 37),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.OpenLink, "[", 1, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "[Named link](https://www.github.com/crescentflare)", 1, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.CloseLink, "]", 1, 11),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.OpenUrl, "(", 1, 12),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.CloseUrl, ")", 1, 49),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 1, 50),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "Quote link: [open Google](https://www.google.com \"Google's homepage\")", 2, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.OpenLink, "[", 2, 12),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.CloseLink, "]", 2, 24),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.OpenUrl, "(", 2, 25),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.DoubleQuote, "\"", 2, 49),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.DoubleQuote, "\"", 2, 67),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.CloseUrl, ")", 2, 68),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 2, 69),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "Some [ random ) link tokens (]]", 3, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.OpenLink, "[", 3, 5),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.CloseUrl, ")", 3, 14),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.OpenUrl, "(", 3, 28),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.CloseLink, "]", 3, 29),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.CloseLink, "]", 3, 30)
        };
        assertSymbols(markdownTextLines, expectedSymbols);
    }

    @Test
    public void testFindEscapeSymbols() {
        String[] markdownTextLines = new String[] {
            "Escaped \\*text style\\* symbols, using the escape character \\\\",
            "\\# This is no header",
            "##\\#\\# But this actually is a header",
            "A fake \\",
            "\\",
            "Newline"
        };
        WrappedMarkdownSymbol[] expectedSymbols = new WrappedMarkdownSymbol[] {
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "Escaped \\*text style\\* symbols, using the escape character \\\\", 0, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Escape, "\\", 0, 8),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Escape, "\\", 0, 19),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Escape, "\\", 0, 57),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 0, 58),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Escape, "\\", 1, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "\\# This is no header", 1, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 1, 19),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Header, "##", 2, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "##\\#\\# But this actually is a header", 2, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Escape, "\\", 2, 2),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Escape, "\\", 2, 3),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Newline, "\n", 2, 34),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.TextBlock, "A fake \\\n\\\nNewline", 3, 0),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Escape, "\\", 3, 7),
            new WrappedMarkdownSymbol(MarkdownSymbol.Type.Escape, "\\", 3, 8)
        };
        assertSymbols(markdownTextLines, expectedSymbols);
    }

    @Test
    public void testEmptyString() {
        assertSymbols(new String[0], new WrappedMarkdownSymbol[0]);
    }


    // --
    // Helpers
    // --

    private void assertSymbols(String[] markdownTextLines, WrappedMarkdownSymbol[] expectedSymbols) {
        // Scan text
        SimpleMarkdownSymbolFinder symbolFinder = new SimpleMarkdownSymbolFinderJava();
        String markdownText = joinWithNewlines(markdownTextLines);
        symbolFinder.scanText(markdownText);

        // Compare
        List<MarkdownSymbol> foundSymbols = symbolFinder.getSymbolStorage().symbols;
        for (int i = 0; i < foundSymbols.size() && i < expectedSymbols.length; i++) {
            Assert.assertEquals(expectedSymbols[i], new WrappedMarkdownSymbol(markdownText, foundSymbols.get(i)));
        }
        Assert.assertEquals(expectedSymbols.length, foundSymbols.size());
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
    // Helper class to simplify comparing symbols
    // --

    private static class WrappedMarkdownSymbol {
        private final MarkdownSymbol.Type type;
        private final String text;
        private final int line;
        private final int linePosition;

        public WrappedMarkdownSymbol(MarkdownSymbol.Type type, String text, int line, int linePosition) {
            this.type = type;
            this.text = text;
            this.line = line;
            this.linePosition = linePosition;
        }

        public WrappedMarkdownSymbol(String markdownText, MarkdownSymbol symbol) {
            this.type = symbol.type;
            this.text = markdownText.substring(symbol.startPosition, symbol.endPosition);
            this.line = symbol.line;
            this.linePosition = symbol.linePosition;
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
            WrappedMarkdownSymbol that = (WrappedMarkdownSymbol)o;
            if (type != that.type) {
                return false;
            }
            if (line != that.line) {
                return false;
            }
            if (linePosition != that.linePosition) {
                return false;
            }
            return text.equals(that.text);
        }

        @Override
        public String toString() {
            return "WrappedMarkdownSymbol{" +
                    "type=" + type +
                    ", text='" + text + '\'' +
                    ", line=" + line +
                    ", linePosition=" + linePosition +
                    '}';
        }
    }
}
