package com.crescentflare.simplemarkdownparser.tagfinder;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/**
 * Simple markdown parser library: processed tag
 * A simplified markdown tag generated after text processing
 */
public class ProcessedMarkdownTag implements Comparable<ProcessedMarkdownTag> {

    // --
    // Members
    // --

    @NotNull public MarkdownTag.Type type;
    public int startPosition;
    public int endPosition;
    public int weight;
    @Nullable public String link;
    public int counter;


    // --
    // Initialization
    // --

    public ProcessedMarkdownTag(@NotNull MarkdownTag.Type type, int weight, int startPosition, int endPosition) {
        this(type, weight, startPosition, endPosition, null);
    }

    public ProcessedMarkdownTag(@NotNull MarkdownTag.Type type, int weight, int startPosition, int endPosition, @Nullable String link) {
        this.type = type;
        this.weight = weight;
        this.startPosition = startPosition;
        this.endPosition = endPosition;
        this.link = link;
    }


    // --
    // Comparable implementation
    // --

    @Override
    public int compareTo(@Nullable ProcessedMarkdownTag other) {
        if (other != null) {
            if (startPosition == other.startPosition) {
                return type.enumIndex() - other.type.enumIndex();
            }
            return startPosition - other.startPosition;
        }
        return 0;
    }
}
