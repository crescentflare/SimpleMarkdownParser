package com.crescentflare.simplemarkdownparser.symbolfinder;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/**
 * Simple markdown parser library: symbol
 * Used to define symbols in a markdown document, like header and text style markers
 */
public class MarkdownSymbol implements Comparable<MarkdownSymbol>
{
    // --
    // Type enum
    // --

    public enum Type {
        Escape,
        DoubleQuote,
        TextBlock,
        Newline,
        Header,
        FirstTextStyle,
        SecondTextStyle,
        ThirdTextStyle,
        OrderedListItem,
        UnorderedListItem,
        OpenLink,
        CloseLink,
        OpenUrl,
        CloseUrl;

        public boolean isTextStyle() {
            return this == FirstTextStyle || this == SecondTextStyle || this == ThirdTextStyle;
        }
    }


    // --
    // Members
    // --

    @NotNull public Type type;
    public int line;
    public int linePosition;
    public int startPosition;
    public int endPosition;


    // --
    // Initialization
    // --

    public MarkdownSymbol(@NotNull Type type, int line, int startPosition, int endPosition, int linePosition) {
        this.type = type;
        this.line = line;
        this.startPosition = startPosition;
        this.endPosition = endPosition;
        this.linePosition = linePosition;
    }


    // --
    // Update position
    // --

    public void updateEndPosition(int position) {
        this.endPosition = position;
    }


    // --
    // Comparable implementation
    // --

    @Override
    public int compareTo(@Nullable MarkdownSymbol other) {
        if (other != null) {
            return startPosition - other.startPosition;
        }
        return 0;
    }
}
