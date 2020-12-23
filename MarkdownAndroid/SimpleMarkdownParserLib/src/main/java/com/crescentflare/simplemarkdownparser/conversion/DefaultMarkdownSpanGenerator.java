package com.crescentflare.simplemarkdownparser.conversion;

import android.content.res.Resources;
import android.graphics.Typeface;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.style.AbsoluteSizeSpan;
import android.text.style.RelativeSizeSpan;
import android.text.style.StrikethroughSpan;
import android.text.style.StyleSpan;
import android.text.style.URLSpan;

import com.crescentflare.simplemarkdownparser.helper.AlignedListSpan;
import com.crescentflare.simplemarkdownparser.tagfinder.MarkdownTag;

import org.jetbrains.annotations.NotNull;

/**
 * Simple markdown parser library: span generator implementation
 * Default implementation of the span generator for markdown conversion
 */
public class DefaultMarkdownSpanGenerator implements MarkdownSpanGenerator {

    // --
    // Implementation
    // --

    @Override
    public void applySpan(@NotNull SpannableStringBuilder builder, @NotNull MarkdownTag.Type type, int weight, int start, int end, @NotNull String extra) {
        switch (type) {
            case Header:
                builder.setSpan(new RelativeSizeSpan(sizeForHeader(weight)), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                builder.setSpan(new StyleSpan(Typeface.BOLD), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                break;
            case OrderedListItem:
            case UnorderedListItem:
                builder.setSpan(new AlignedListSpan(extra, 30 + (weight - 1) * 15, 5), start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                break;
            case TextStyle:
                builder.setSpan(new StyleSpan(textStyleForWeight(weight)), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                break;
            case AlternativeTextStyle:
                builder.setSpan(new StrikethroughSpan(), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                break;
            case Link:
                builder.setSpan(new URLSpan(extra), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                break;
        }
    }

    public void applySectionSpacerAttribute(@NotNull SpannableStringBuilder builder, @NotNull MarkdownTag.Type previousSectionType, int previousSectionWeight, @NotNull MarkdownTag.Type nextSectionType, int nextSectionWeight, int start, int end) {
        int spacing = nextSectionType == MarkdownTag.Type.Header && previousSectionType != MarkdownTag.Type.Header ? 16 : 8;
        builder.setSpan(new AbsoluteSizeSpan((int)(Resources.getSystem().getDisplayMetrics().density * spacing)), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
    }

    @Override
    @NotNull public String getListToken(@NotNull MarkdownTag.Type type, int weight, int index) {
        return type == MarkdownTag.Type.OrderedListItem ? "" + index + "." : bulletTokenForWeight(weight);
    }


    // --
    // Helpers
    // --

    private static float sizeForHeader(int weight) {
        if (weight >= 1 && weight < 6) {
            return 1.5f - (float)(weight - 1) * 0.1f;
        }
        return 1.0f;
    }

    private static int textStyleForWeight(int weight) {
        switch (weight) {
            case 1:
                return Typeface.ITALIC;
            case 2:
                return Typeface.BOLD;
            case 3:
                return Typeface.BOLD_ITALIC;
        }
        return Typeface.NORMAL;
    }

    private static String bulletTokenForWeight(int weight) {
        if (weight == 2) {
            return "\u25E6 ";
        } else if (weight >= 3) {
            return "\u25AA ";
        }
        return "\u2022 ";
    }
}
