package com.crescentflare.simplemarkdownparser.conversion;

import android.text.SpannableStringBuilder;
import android.text.Spanned;

import com.crescentflare.simplemarkdownparser.symbolfinder.SimpleMarkdownSymbolFinder;
import com.crescentflare.simplemarkdownparser.symbolfinder.SimpleMarkdownSymbolFinderJava;
import com.crescentflare.simplemarkdownparser.symbolfinder.SimpleMarkdownSymbolFinderNative;
import com.crescentflare.simplemarkdownparser.tagfinder.MarkdownTag;
import com.crescentflare.simplemarkdownparser.tagfinder.ProcessedMarkdownTag;
import com.crescentflare.simplemarkdownparser.tagfinder.SimpleMarkdownTagFinder;

import org.jetbrains.annotations.NotNull;

import java.util.List;

/**
 * Simple markdown parser library: markdown text converter
 * Convert markdown to other formats usable for Android (like html or spannable strings)
 */
public class SimpleMarkdownConverter {

    // --
    // Static member to determine availability of the native core symbol finder implementation
    // --

    private static int nativeParserLibraryLoaded = 0;


    // --
    // HTML conversion handling
    // --

    @NotNull public static String toHtmlString(@NotNull String markdownText) {
        // Find symbols
        SimpleMarkdownSymbolFinder symbolFinder = obtainSymbolFinder(markdownText);
        symbolFinder.scanText(markdownText);

        // Find tags from symbols and process text
        SimpleMarkdownTagFinder tagFinder = new SimpleMarkdownTagFinder();
        List<MarkdownTag> tags = tagFinder.findTags(markdownText, symbolFinder.getSymbolStorage().symbols);
        SimpleMarkdownTextProcessor processor = SimpleMarkdownTextProcessor.process(markdownText, tags);

        // Process HTML
        SimpleMarkdownHtmlProcessor htmlProcessor = SimpleMarkdownHtmlProcessor.process(processor.text, processor.tags);
        return htmlProcessor.text;
    }


    // --
    // Spannable conversion handling
    // --

    @NotNull public static Spanned toSpannable(@NotNull String markdownText) {
        return toSpannable(markdownText, new DefaultMarkdownSpanGenerator());
    }

    @NotNull public static Spanned toSpannable(@NotNull String markdownText, @NotNull MarkdownSpanGenerator spanGenerator) {
        // Find symbols
        SimpleMarkdownSymbolFinder symbolFinder = obtainSymbolFinder(markdownText);
        symbolFinder.scanText(markdownText);

        // Find tags from symbols and process text
        SimpleMarkdownTagFinder tagFinder = new SimpleMarkdownTagFinder();
        List<MarkdownTag> tags = tagFinder.findTags(markdownText, symbolFinder.getSymbolStorage().symbols);
        SimpleMarkdownTextProcessor processor = SimpleMarkdownTextProcessor.process(markdownText, tags, spanGenerator);
        processor.rearrangeNestedTextStyles();

        // Set up spannable
        SpannableStringBuilder spannableString = new SpannableStringBuilder(processor.text);
        for (int index = 0; index < processor.tags.size(); index++) {
            // Handle section spacer
            ProcessedMarkdownTag tag = processor.tags.get(index);
            if (tag.type == MarkdownTag.Type.SectionSpacer) {
                MarkdownTag.Type previousSectionTagType = null;
                MarkdownTag.Type nextSectionTagType = null;
                int previousSectionWeight = 0;
                int nextSectionWeight = 0;
                for (int checkIndex = 0; checkIndex < processor.tags.size(); checkIndex++) {
                    ProcessedMarkdownTag checkTag = processor.tags.get(checkIndex);
                    if (checkTag.type.isSection()) {
                        if (checkIndex < index) {
                            previousSectionTagType = checkTag.type;
                            previousSectionWeight = checkTag.weight;
                        } else if (checkIndex > index) {
                            nextSectionTagType = checkTag.type;
                            nextSectionWeight = checkTag.weight;
                            break;
                        }
                    }
                }
                if (previousSectionTagType != null && nextSectionTagType != null) {
                    spanGenerator.applySectionSpacerSpan(spannableString, previousSectionTagType, previousSectionWeight, nextSectionTagType, nextSectionWeight, tag.startPosition, tag.endPosition);
                }
            }

            // Apply span from tag
            String extra = "";
            if (tag.type == MarkdownTag.Type.OrderedListItem || tag.type == MarkdownTag.Type.UnorderedListItem) {
                extra = spanGenerator.getListToken(tag.type, tag.weight, tag.counter);
            } else if (tag.link != null) {
                extra = tag.link;
            }
            spanGenerator.applySpan(spannableString, tag.type, tag.weight, tag.startPosition, tag.endPosition, extra);
        }
        return spannableString;
    }


    // --
    // Obtain symbol finder instance based on requirements
    // --

    private static SimpleMarkdownSymbolFinder obtainSymbolFinder(String text) {
        if (nativeParserLibraryLoaded == 0) {
            try {
                System.loadLibrary("simplemarkdownparser_native");
                nativeParserLibraryLoaded = 1;
            } catch (Throwable t) {
                nativeParserLibraryLoaded = -1;
            }
        }
        return text.length() > 128 && nativeParserLibraryLoaded == 1 ? new SimpleMarkdownSymbolFinderNative() : new SimpleMarkdownSymbolFinderJava();
    }
}
