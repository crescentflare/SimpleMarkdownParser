package com.crescentflare.simplemarkdownparser.core;

/**
 * Simple markdown parser core library: interface class
 * The interface to do the core (low-level) markdown parsing
 * It returns ranges for the markdown tags which is used within the library
 * Use manually if the output needs to be highly customizable
 */
public interface SimpleMarkdownParser
{
    enum ExtractBetweenMode
    {
        StartToNext,
        IntermediateToNext,
        IntermediateToEnd
    }

    MarkdownTag[] findTags(String markdownText);
    String extractText(String markdownText, MarkdownTag tag);
    String extractTextBetween(String markdownText, MarkdownTag startTag, MarkdownTag endTag, ExtractBetweenMode mode);
    String extractFull(String markdownText, MarkdownTag tag);
    String extractFullBetween(String markdownText, MarkdownTag startTag, MarkdownTag endTag, ExtractBetweenMode mode);
    String extractExtra(String markdownText, MarkdownTag tag);
}
