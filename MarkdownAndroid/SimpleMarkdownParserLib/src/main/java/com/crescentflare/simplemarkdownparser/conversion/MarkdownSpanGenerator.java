package com.crescentflare.simplemarkdownparser.conversion;

import android.text.SpannableStringBuilder;

import com.crescentflare.simplemarkdownparser.tagfinder.MarkdownTag;

import org.jetbrains.annotations.NotNull;

/**
 * Simple markdown parser library: helper class
 * An interface to generate spans for markdown tags
 * Provide an implementation to customize styling
 */
public interface MarkdownSpanGenerator {
    void applySpan(@NotNull SpannableStringBuilder builder, @NotNull MarkdownTag.Type type, int weight, int start, int end, @NotNull String extra);
    void applySectionSpacerSpan(@NotNull SpannableStringBuilder builder, @NotNull MarkdownTag.Type previousSectionType, int previousSectionWeight, @NotNull MarkdownTag.Type nextSectionType, int nextSectionWeight, int start, int end);
    @NotNull String getListToken(@NotNull MarkdownTag.Type type, int weight, int index);
}
