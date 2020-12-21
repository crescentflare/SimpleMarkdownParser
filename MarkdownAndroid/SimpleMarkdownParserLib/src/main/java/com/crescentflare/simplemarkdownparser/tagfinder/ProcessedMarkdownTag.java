package com.crescentflare.simplemarkdownparser.tagfinder;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/**
 * Simple markdown parser library: processed tag
 * A simplified markdown tag generated after text processing
 */
public class ProcessedMarkdownTag {

    // --
    // Members
    // --

    @NotNull public MarkdownTag.Type type;
    public int startPosition;
    public int endPosition;
    public int weight;
    @Nullable public String link;


    // --
    // Initialization
    // --

    public ProcessedMarkdownTag(@NotNull MarkdownTag.Type type, int weight, int startPosition, int endPosition, @Nullable String link) {
        this.type = type;
        this.weight = weight;
        this.startPosition = startPosition;
        this.endPosition = endPosition;
        this.link = link;
    }
}
