package com.crescentflare.simplemarkdownparser.tagfinder;

import com.crescentflare.simplemarkdownparser.symbolfinder.MarkdownSymbol;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.ArrayList;
import java.util.List;

/**
 * Simple markdown parser library: tag
 * A markdown paragraph, heading or styling tag found within the markdown text
 */
public class MarkdownTag implements Comparable<MarkdownTag> {

    // --
    // Type enum
    // --

    public enum Type {
        Paragraph,
        Header,
        List,
        Line,
        SectionSpacer,
        OrderedListItem,
        UnorderedListItem,
        Link,
        TextStyle,
        AlternativeTextStyle;

        public boolean isSection() {
            return this == Paragraph || this == Header || this == List;
        }

        public int enumIndex() {
            for (int i = 0; i < values().length; i++) {
                if (values()[i] == this) {
                    return i;
                }
            }
            return -1;
        }
    }


    // --
    // Members
    // --

    @NotNull public Type type;
    public int startPosition;
    public int endPosition;
    public int startText;
    public int endText;
    public int startExtra;
    public int endExtra;
    public int weight;
    public List<MarkdownSymbol> escapeSymbols;


    // --
    // Initialization
    // --

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


    // --
    // Comparable implementation
    // --

    @Override
    public int compareTo(@Nullable MarkdownTag other) {
        if (other != null) {
            if (startPosition == other.startPosition) {
                return type.enumIndex() - other.type.enumIndex();
            }
            return startPosition - other.startPosition;
        }
        return 0;
    }
}
