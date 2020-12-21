package com.crescentflare.simplemarkdownparser.conversion;

import android.graphics.Typeface;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.style.RelativeSizeSpan;
import android.text.style.StrikethroughSpan;
import android.text.style.StyleSpan;
import android.text.style.URLSpan;

import com.crescentflare.simplemarkdownparser.conversion.MarkdownSpanGenerator;
import com.crescentflare.simplemarkdownparser.helper.AlignedListSpan;
import com.crescentflare.simplemarkdownparser.tagfinder.MarkdownTag;

/**
 * Simple markdown parser library: helper class
 * Default implementation of the span generator for markdown conversion
 */
public class DefaultMarkdownSpanGenerator implements MarkdownSpanGenerator {
    @Override
    public void applySpan(SpannableStringBuilder builder, MarkdownTag.Type type, int weight, int start, int end, String extra) {
        switch (type) {
            case Paragraph:
                builder.setSpan(new RelativeSizeSpan(weight), start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                break;
            case Header:
                builder.setSpan(new RelativeSizeSpan(sizeForHeader(weight)), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                builder.setSpan(new StyleSpan(Typeface.BOLD), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                break;
            case OrderedList:
            case UnorderedList:
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

    @Override
    public String getListToken(MarkdownTag.Type type, int weight, int index) {
        return type == MarkdownTag.Type.OrderedList ? "" + index + "." : bulletTokenForWeight(weight);
    }

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
