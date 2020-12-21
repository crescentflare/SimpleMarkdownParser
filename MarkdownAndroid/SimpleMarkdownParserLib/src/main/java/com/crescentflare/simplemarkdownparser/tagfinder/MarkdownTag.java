package com.crescentflare.simplemarkdownparser.tagfinder;

import com.crescentflare.simplemarkdownparser.symbolfinder.MarkdownSymbol;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.List;

/**
 * Simple markdown parser library: tag
 * A markdown paragraph, heading or styling tag found within the markdown text
 */
public class MarkdownTag {

    // --
    // Type enum
    // --

    public enum Type {
        Normal, // To be deprecated
        Paragraph,
        Header,
        List,
        Line,
        SectionSpacer,
        OrderedList,
        UnorderedList,
        Link,
        TextStyle,
        AlternativeTextStyle;

        public boolean isSection() {
            return this == Paragraph || this == Header || this == List;
        }
    }


    // --
    // Members
    // --

    public static final int FLAG_NONE = 0x0; // To be deprecated
    public static final int FLAG_ESCAPED = 0x40000000; // To be deprecated

    @NotNull public Type type = Type.Normal;
    public int flags = FLAG_NONE; // To be deprecated
    public int startPosition = -1;
    public int endPosition = -1;
    public int startText = -1;
    public int endText = -1;
    public int startExtra = -1;
    public int endExtra = -1;
    public int weight = 0;
    public int nativeInfo[] = null; // To be deprecated
    public List<MarkdownSymbol> escapeSymbols = new ArrayList<>();


    // --
    // Initialization
    // --

    public MarkdownTag() { // To be deprecated
    }

    public MarkdownTag(@NotNull Type type, int weight, int startPosition, int endPosition) {
        this(type, weight, startPosition, endPosition, startPosition, endPosition, -1, -1, new ArrayList<MarkdownSymbol>());
    }

    public MarkdownTag(@NotNull Type type, int weight, int startPosition, int endPosition, @NotNull List<MarkdownSymbol> escapeSymbols) {
        this(type, weight, startPosition, endPosition, startPosition, endPosition, -1, -1, escapeSymbols);
    }

    public MarkdownTag(@NotNull Type type, int weight, int startPosition, int endPosition, int startText, int endText) {
        this(type, weight, startPosition, endPosition, startText, endText, -1, -1, new ArrayList<MarkdownSymbol>());
    }

    public MarkdownTag(@NotNull Type type, int weight, int startPosition, int endPosition, int startText, int endText, @NotNull List<MarkdownSymbol> escapeSymbols) {
        this(type, weight, startPosition, endPosition, startText, endText, -1, -1, escapeSymbols);
    }

    public MarkdownTag(@NotNull Type type, int weight, int startPosition, int endPosition, int startText, int endText, int startExtra, int endExtra) {
        this(type, weight, startPosition, endPosition, startText, endText, startExtra, endExtra, new ArrayList<MarkdownSymbol>());
    }

    public MarkdownTag(@NotNull Type type, int weight, int startPosition, int endPosition, int startText, int endText, int startExtra, int endExtra, @NotNull List<MarkdownSymbol> escapeSymbols) {
        this.type = type;
        this.weight = weight;
        this.startPosition = startPosition;
        this.endPosition = endPosition;
        this.startText = startText;
        this.endText = endText;
        this.startExtra = startExtra;
        this.endExtra = endExtra;
        this.escapeSymbols = escapeSymbols;
    }
}
