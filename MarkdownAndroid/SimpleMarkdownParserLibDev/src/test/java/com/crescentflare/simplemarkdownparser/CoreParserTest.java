package com.crescentflare.simplemarkdownparser;

import com.crescentflare.simplemarkdownparsercore.SimpleMarkdownJavaParser;
import com.crescentflare.simplemarkdownparsercore.SimpleMarkdownParser;
import com.crescentflare.simplemarkdownparsercore.MarkdownTag;

import junit.framework.Assert;

import org.junit.Test;

/**
 * Unit test: core parser
 * Tests the core parser library (native and java)
 */
public class CoreParserTest
{
    /**
     * Tests
     */
    @Test
    public void testFindTagsNewlines()
    {
        //Test case with given text and expected markdown tags
        String[] markdownTextLines = new String[]
        {
                "",
                "",
                "Text",
                "",
                "",
                "",
                "Another",
                ""
        };
        WrappedMarkdownTag[] expectedTags = new WrappedMarkdownTag[]
        {
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Text"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Another")
        };
        assertTags(markdownTextLines, expectedTags);
    }

    @Test
    public void testFindTagsHeaders()
    {
        //Test case with given text and expected markdown tags
        String[] markdownTextLines = new String[]
        {
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
        WrappedMarkdownTag[] expectedTags = new WrappedMarkdownTag[]
        {
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Some text"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 2, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Header, 1, MarkdownTag.FLAG_NONE, "First header"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Additional text"),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "And more"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 2, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Header, 2, MarkdownTag.FLAG_NONE, "Last header"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Final text")
        };
        assertTags(markdownTextLines, expectedTags);
    }

    @Test
    public void testFindTagsSections()
    {
        //Test case with given text and expected markdown tags
        String[] markdownTextLines = new String[]
        {
                "",
                "",
                "  #A strange indented header",
                "Another piece of text",
                "  ",
                "Text with a space separator to prevent paragraph",
                "",
                "New paragraph",
                "  # Sudden header",
                "Text",
                "",
                "* Bullet item",
                "* Second item",
                "  With some text",
                "",
                "New paragraph"
        };
        WrappedMarkdownTag[] expectedTags = new WrappedMarkdownTag[]
        {
                new WrappedMarkdownTag(MarkdownTag.Type.Header, 1, MarkdownTag.FLAG_NONE, "A strange indented header"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Another piece of text"),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Text with a space separator to prevent paragraph"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "New paragraph"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 2, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Header, 1, MarkdownTag.FLAG_NONE, "Sudden header"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Text"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.UnorderedList, 1, MarkdownTag.FLAG_NONE, "Bullet item"),
                new WrappedMarkdownTag(MarkdownTag.Type.UnorderedList, 1, MarkdownTag.FLAG_NONE, "Second item"),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "With some text"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "New paragraph")
        };
        assertTags(markdownTextLines, expectedTags);
    }

    @Test
    public void testFindTagsStyling()
    {
        //Test case with given text and expected markdown tags
        String[] markdownTextLines = new String[]
        {
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
                "",
                "And some text afterwards with a [link](https://www.github.com)."
        };
        WrappedMarkdownTag[] expectedTags = new WrappedMarkdownTag[]
        {
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Some text **before** the captions"),
                new WrappedMarkdownTag(MarkdownTag.Type.TextStyle, 2, MarkdownTag.FLAG_NONE, "before"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 2, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Header, 1, MarkdownTag.FLAG_NONE, "Caption 1"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Some lines of _styled and **double styled** text_ which should be formatted correctly."),
                new WrappedMarkdownTag(MarkdownTag.Type.TextStyle, 1, MarkdownTag.FLAG_NONE, "styled and **double styled** text"),
                new WrappedMarkdownTag(MarkdownTag.Type.TextStyle, 2, MarkdownTag.FLAG_NONE, "double styled"),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "Also new lines should work properly."),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 2, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Header, 3, MarkdownTag.FLAG_NONE, "Caption 3"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_ESCAPED, "The caption above is a bit smaller. Below add more lines to start a new *paragraph*."),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "New paragraph here with ~~strike through text in **bold**~~."),
                new WrappedMarkdownTag(MarkdownTag.Type.AlternativeTextStyle, 2, MarkdownTag.FLAG_NONE, "strike through text in **bold**"),
                new WrappedMarkdownTag(MarkdownTag.Type.TextStyle, 2, MarkdownTag.FLAG_NONE, "bold"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.UnorderedList, 1, MarkdownTag.FLAG_NONE, "A bullet list"),
                new WrappedMarkdownTag(MarkdownTag.Type.UnorderedList, 1, MarkdownTag.FLAG_NONE, "Second bullet item"),
                new WrappedMarkdownTag(MarkdownTag.Type.UnorderedList, 2, MarkdownTag.FLAG_NONE, "A nested item"),
                new WrappedMarkdownTag(MarkdownTag.Type.UnorderedList, 1, MarkdownTag.FLAG_NONE, "Third bullet item"),
                new WrappedMarkdownTag(MarkdownTag.Type.OrderedList, 2, MarkdownTag.FLAG_NONE, "Nested first item"),
                new WrappedMarkdownTag(MarkdownTag.Type.OrderedList, 2, MarkdownTag.FLAG_NONE, "Nested second item"),
                new WrappedMarkdownTag(MarkdownTag.Type.Paragraph, 1, MarkdownTag.FLAG_NONE, ""),
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "And some text afterwards with a [link](https://www.github.com)."),
                new WrappedMarkdownTag(MarkdownTag.Type.Link, MarkdownTag.FLAG_NONE, "link", "https://www.github.com")
        };
        assertTags(markdownTextLines, expectedTags);
    }

    @Test
    public void testFindTagsEdgeCases()
    {
        //Test case with given text and expected markdown tags
        String[] markdownTextLines = new String[]
        {
                "A strange ***combination** tag*."
        };
        WrappedMarkdownTag[] expectedTags = new WrappedMarkdownTag[]
        {
                new WrappedMarkdownTag(MarkdownTag.Type.Normal, MarkdownTag.FLAG_NONE, "A strange ***combination** tag*."),
                new WrappedMarkdownTag(MarkdownTag.Type.TextStyle, 2, MarkdownTag.FLAG_NONE, "*combination")
        };
        assertTags(markdownTextLines, expectedTags);
    }

    /**
     * Helpers
     */
    private void assertTags(String[] markdownTextLines, WrappedMarkdownTag[] expectedTags)
    {
        SimpleMarkdownParser parser = new SimpleMarkdownJavaParser();
        String markdownText = joinWithNewlines(markdownTextLines);
        MarkdownTag[] foundTags = parser.findTags(markdownText);
        for (int i = 0; i < foundTags.length && i < expectedTags.length; i++)
        {
            Assert.assertEquals(expectedTags[i], new WrappedMarkdownTag(markdownText, foundTags[i]));
        }
        Assert.assertEquals(expectedTags.length, foundTags.length);
    }

    private String joinWithNewlines(String[] stringArray)
    {
        String joinedText = "";
        boolean firstLine = true;
        for (String string : stringArray)
        {
            if (!firstLine)
            {
                joinedText += "\n";
            }
            joinedText += string;
            firstLine = false;
        }
        return joinedText;
    }

    /**
     * Helper class to simply compare tags
     */
    private static class WrappedMarkdownTag
    {
        private MarkdownTag.Type type;
        private int flags;
        private int weight;
        private String text;
        private String extra;

        public WrappedMarkdownTag(MarkdownTag.Type type, int flags, String text)
        {
            this(type, 0, flags, text, "");
        }

        public WrappedMarkdownTag(MarkdownTag.Type type, int flags, String text, String extra)
        {
            this(type, 0, flags, text, extra);
        }

        public WrappedMarkdownTag(MarkdownTag.Type type, int weight, int flags, String text)
        {
            this(type, weight, 0, text, "");
        }

        public WrappedMarkdownTag(MarkdownTag.Type type, int weight, int flags, String text, String extra)
        {
            this.type = type;
            this.weight = weight;
            this.flags = flags;
            this.text = text;
            this.extra = extra;
        }

        public WrappedMarkdownTag(String markdownText, MarkdownTag tag)
        {
            this.type = tag.type;
            this.weight = tag.weight;
            this.flags = tag.flags;
            this.text = new SimpleMarkdownJavaParser().extractText(markdownText, tag);
            this.extra = new SimpleMarkdownJavaParser().extractExtra(markdownText, tag);
        }

        @Override
        public boolean equals(Object o)
        {
            if (this == o)
            {
                return true;
            }
            if (o == null || getClass() != o.getClass())
            {
                return false;
            }
            WrappedMarkdownTag that = (WrappedMarkdownTag)o;
            if (type != that.type)
            {
                return false;
            }
            if (weight != that.weight)
            {
                return false;
            }
            if (flags != that.flags)
            {
                return false;
            }
            if (!extra.equals(that.extra))
            {
                return false;
            }
            return text.equals(that.text);
        }

        @Override
        public String toString()
        {
            return "WrappedMarkdownTag{" +
                    "type=" + type +
                    ", flags=" + flags +
                    ", weight=" + weight +
                    ", text='" + text + '\'' +
                    ", extra='" + extra + '\'' +
                    '}';
        }
    }
}
