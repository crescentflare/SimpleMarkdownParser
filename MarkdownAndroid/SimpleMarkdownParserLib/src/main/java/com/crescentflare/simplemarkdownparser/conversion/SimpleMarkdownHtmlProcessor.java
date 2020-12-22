package com.crescentflare.simplemarkdownparser.conversion;

import com.crescentflare.simplemarkdownparser.tagfinder.MarkdownTag;
import com.crescentflare.simplemarkdownparser.tagfinder.ProcessedMarkdownTag;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * Simple markdown parser library: HTML conversion
 * Helper class to generate HTML tags which are inserted into the processed markdown text
 */
public class SimpleMarkdownHtmlProcessor {

    // --
    // Members
    // --

    @NotNull public String text = "";
    private final StringBuilder textBuilder;
    private final ArrayList<MarkdownHtmlTag> htmlTags = new ArrayList<>();
    private final List<ProcessedMarkdownTag> markdownTags;


    // --
    // Initialization
    // --

    private SimpleMarkdownHtmlProcessor(String text, List<ProcessedMarkdownTag> tags) {
        textBuilder = new StringBuilder(text);
        this.markdownTags = tags;
    }


    // --
    // Processing
    // --

    public static SimpleMarkdownHtmlProcessor process(@NotNull String text, @NotNull List<ProcessedMarkdownTag> tags) {
        SimpleMarkdownHtmlProcessor instance = new SimpleMarkdownHtmlProcessor(text, tags);
        instance.processInternal();
        return instance;
    }

    private void processInternal() {
        // Process markdown tags
        ArrayList<ProcessedMarkdownTag> sectionTags = new ArrayList<>();
        for (ProcessedMarkdownTag tag : markdownTags) {
            if (tag.type.isSection()) {
                sectionTags.add(tag);
            }
        }
        for (ProcessedMarkdownTag sectionTag : sectionTags) {
            // First add section html tags
            if (sectionTag.type == MarkdownTag.Type.Paragraph) {
                htmlTags.add(new MarkdownHtmlTag(sectionTag.startPosition, MarkdownHtmlTagType.OpenParagraph, htmlTags.size()));
                htmlTags.add(new MarkdownHtmlTag(sectionTag.endPosition, MarkdownHtmlTagType.CloseParagraph, htmlTags.size()));
            } else if (sectionTag.type == MarkdownTag.Type.Header) {
                int clippedWeight = Math.max(1, Math.min(sectionTag.weight, 6));
                htmlTags.add(new MarkdownHtmlTag(sectionTag.startPosition, MarkdownHtmlTagType.allOpenHeaders.get(clippedWeight - 1), htmlTags.size()));
                htmlTags.add(new MarkdownHtmlTag(sectionTag.endPosition, MarkdownHtmlTagType.allCloseHeaders.get(clippedWeight - 1), htmlTags.size()));
            }

            // Process inner tags
            ArrayList<ProcessedMarkdownTag> innerTags = new ArrayList<>();
            ArrayList<ProcessedMarkdownTag> innerListTags = new ArrayList<>();
            for (ProcessedMarkdownTag tag : markdownTags) {
                if (!tag.type.isSection() && tag.startPosition >= sectionTag.startPosition && tag.endPosition <= sectionTag.endPosition) {
                    innerTags.add(tag);
                }
            }
            for (ProcessedMarkdownTag tag : innerTags) {
                if (tag.type == MarkdownTag.Type.OrderedList || tag.type == MarkdownTag.Type.UnorderedList) {
                    innerListTags.add(tag);
                }
            }
            if (innerListTags.size() > 0) {
                addHtmlListTags(innerListTags, 0, innerListTags.size(), 1);
            }
            for (ProcessedMarkdownTag tag : innerTags) {
                switch (tag.type) {
                    case TextStyle:
                        int clippedWeight = Math.max(1, Math.min(tag.weight, 3));
                        htmlTags.add(new MarkdownHtmlTag(tag.startPosition, MarkdownHtmlTagType.allOpenTextStyles.get(clippedWeight - 1), htmlTags.size()));
                        htmlTags.add(new MarkdownHtmlTag(tag.endPosition, MarkdownHtmlTagType.allCloseTextStyles.get(clippedWeight - 1), htmlTags.size()));
                        break;
                    case AlternativeTextStyle:
                        htmlTags.add(new MarkdownHtmlTag(tag.startPosition, MarkdownHtmlTagType.OpenAlternativeTextStyle, htmlTags.size()));
                        htmlTags.add(new MarkdownHtmlTag(tag.endPosition, MarkdownHtmlTagType.CloseAlternativeTextStyle, htmlTags.size()));
                        break;
                    case Link:
                        htmlTags.add(new MarkdownHtmlTag(tag.startPosition, MarkdownHtmlTagType.OpenLink, htmlTags.size(), tag.link));
                        htmlTags.add(new MarkdownHtmlTag(tag.endPosition, MarkdownHtmlTagType.CloseLink, htmlTags.size()));
                        break;
                    case OrderedList:
                    case UnorderedList:
                        htmlTags.add(new MarkdownHtmlTag(tag.startPosition, MarkdownHtmlTagType.OpenListItem, htmlTags.size()));
                        htmlTags.add(new MarkdownHtmlTag(tag.endPosition, MarkdownHtmlTagType.CloseListItem, htmlTags.size()));
                        break;
                    case Line:
                        MarkdownHtmlTag htmlTag = new MarkdownHtmlTag(tag.endPosition, MarkdownHtmlTagType.LineBreak, htmlTags.size());
                        htmlTag.preventCancellation = sectionTag.type == MarkdownTag.Type.List && tag.endPosition == sectionTag.endPosition;
                        htmlTags.add(htmlTag);
                        break;
                    default:
                        break;
                }
            }
        }

        // Remove line breaks canceled by other html tags
        ArrayList<Integer> removeIndices = new ArrayList<>();
        for (int index = 0; index < htmlTags.size(); index++) {
            if (htmlTags.get(index).tag == MarkdownHtmlTagType.LineBreak && !htmlTags.get(index).preventCancellation) {
                for (int checkIndex = 0; checkIndex < htmlTags.size(); checkIndex++) {
                    if (checkIndex != index && htmlTags.get(index).position == htmlTags.get(checkIndex).position && htmlTags.get(checkIndex).tag.cancelsLineBreak()) {
                        removeIndices.add(index);
                        break;
                    }
                }
            }
        }
        for (int i = removeIndices.size() - 1; i >= 0; i--) {
            int removeIndex = removeIndices.get(i);
            htmlTags.remove(removeIndex);
        }

        // Sort and insert in text (start at the end, to easily insert without taking string position changes into account)
        Collections.sort(htmlTags);
        for (MarkdownHtmlTag htmlTag : htmlTags) {
            textBuilder.insert(htmlTag.position, htmlTag.insertToken());
        }
        text = textBuilder.toString();
    }


    // --
    // Helper
    // --

    private void addHtmlListTags(List<ProcessedMarkdownTag> innerTags, int index, int untilIndex, int weight) {
        // Find start index for tag matching weight, return early if none are found
        int startIndex = -1;
        for (int i = index; i < untilIndex; i++) {
            int tagWeight = Math.max(1, innerTags.get(i).weight);
            if (tagWeight >= weight) {
                startIndex = i;
                break;
            }
        }
        if (startIndex < index) {
            return;
        }

        // Find end index
        MarkdownTag.Type checkType = innerTags.get(startIndex).weight == weight ? innerTags.get(startIndex).type : MarkdownTag.Type.List;
        int endIndex = startIndex + 1;
        for (int i = startIndex + 1; i < untilIndex; i++) {
            int tagWeight = Math.max(1, innerTags.get(i).weight);
            if (checkType == MarkdownTag.Type.List && tagWeight == weight) {
                checkType = innerTags.get(i).type;
            }
            if (tagWeight < weight || (tagWeight == weight && innerTags.get(i).type != checkType)) {
                break;
            }
            endIndex += 1;
        }

        // Insert list section tags
        htmlTags.add(new MarkdownHtmlTag(innerTags.get(startIndex).startPosition, checkType == MarkdownTag.Type.OrderedList ? MarkdownHtmlTagType.OpenOrderedList : MarkdownHtmlTagType.OpenUnorderedList, htmlTags.size()));
        htmlTags.add(new MarkdownHtmlTag(innerTags.get(endIndex - 1).endPosition, checkType == MarkdownTag.Type.OrderedList ? MarkdownHtmlTagType.CloseOrderedList : MarkdownHtmlTagType.CloseUnorderedList, htmlTags.size()));

        // Call recursively for a higher weight, or continuation into a different list type
        addHtmlListTags(innerTags, startIndex, endIndex, weight + 1);
        if (endIndex < untilIndex) {
            addHtmlListTags(innerTags, endIndex, untilIndex, weight);
        }
    }


    // --
    // Enum for HTML tag types
    // --

    private enum MarkdownHtmlTagType {
        LineBreak("<br/>"),
        OpenHeader1("<h1>"),
        CloseHeader1("</h1>"),
        OpenHeader2("<h2>"),
        CloseHeader2("</h2>"),
        OpenHeader3("<h3>"),
        CloseHeader3("</h3>"),
        OpenHeader4("<h4>"),
        CloseHeader4("</h4>"),
        OpenHeader5("<h5>"),
        CloseHeader5("</h5>"),
        OpenHeader6("<h6>"),
        CloseHeader6("</h6>"),
        OpenParagraph("<p>"),
        CloseParagraph("</p>"),
        OpenUnorderedList("<ul>"),
        CloseUnorderedList("</ul>"),
        OpenOrderedList("<ol>"),
        CloseOrderedList("</ol>"),
        OpenListItem("<li>"),
        CloseListItem("</li>"),
        OpenTextStyle1("<i>"),
        CloseTextStyle1("</i>"),
        OpenTextStyle2("<b>"),
        CloseTextStyle2("</b>"),
        OpenTextStyle3("<b><i>"),
        CloseTextStyle3("</i></b>"),
        OpenAlternativeTextStyle("<del>"),
        CloseAlternativeTextStyle("</del>"),
        OpenLink("<a href=\"#\">"),
        CloseLink("</a>");

        private final String stringValue;

        MarkdownHtmlTagType(String stringValue) {
            this.stringValue = stringValue;
        }

        @Override
        public String toString() {
            return stringValue;
        }

        static List<MarkdownHtmlTagType> allOpenHeaders = new ArrayList<>(Arrays.asList(OpenHeader1, OpenHeader2, OpenHeader3, OpenHeader4, OpenHeader5, OpenHeader6));
        static List<MarkdownHtmlTagType> allCloseHeaders = new ArrayList<>(Arrays.asList(CloseHeader1, CloseHeader2, CloseHeader3, CloseHeader4, CloseHeader5, CloseHeader6));
        static List<MarkdownHtmlTagType> allOpenTextStyles = new ArrayList<>(Arrays.asList(OpenTextStyle1, OpenTextStyle2, OpenTextStyle3));
        static List<MarkdownHtmlTagType> allCloseTextStyles = new ArrayList<>(Arrays.asList(CloseTextStyle1, CloseTextStyle2, CloseTextStyle3));

        boolean cancelsLineBreak() {
            return allCloseHeaders.contains(this) || this == CloseParagraph || this == CloseUnorderedList || this == CloseOrderedList || this == CloseListItem;
        }

        boolean isClosingTag() {
            return allCloseHeaders.contains(this) || allCloseTextStyles.contains(this) || this == CloseParagraph || this == CloseUnorderedList || this == CloseOrderedList || this == CloseListItem || this == CloseAlternativeTextStyle || this == CloseLink;
        }

        int priority() {
            if (this == LineBreak) {
                return 2;
            }
            if (isClosingTag()) {
                return 1;
            }
            return 0;
        }
    }


    // --
    // Internal HTML tag class
    // --

    private static class MarkdownHtmlTag implements Comparable<MarkdownHtmlTag> {
        int position;
        MarkdownHtmlTagType tag;
        int counter;
        String value;
        boolean preventCancellation = false;

        MarkdownHtmlTag(int position, MarkdownHtmlTagType tag, int counter) {
            this(position, tag, counter, null);
        }

        MarkdownHtmlTag(int position, MarkdownHtmlTagType tag, int counter, String value) {
            this.position = position;
            this.tag = tag;
            this.counter = counter;
            this.value = value;
        }

        String insertToken() {
            if (value != null) {
                return tag.toString().replace("#", value);
            }
            return tag.toString();
        }

        @Override
        public int compareTo(@Nullable MarkdownHtmlTag other) {
            if (other != null) {
                if (position != other.position) {
                    return other.position - position;
                } else if (tag.priority() != other.tag.priority()) {
                    return other.tag.priority() - tag.priority();
                } else {
                    return tag.isClosingTag() ? counter - other.counter : other.counter - counter;
                }
            }
            return 0;
        }
    }
}
