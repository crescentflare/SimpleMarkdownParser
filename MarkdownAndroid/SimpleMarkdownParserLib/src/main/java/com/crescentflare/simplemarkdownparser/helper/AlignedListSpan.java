package com.crescentflare.simplemarkdownparser.helper;

import android.content.res.Resources;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.text.Layout;
import android.text.Spanned;
import android.text.style.LeadingMarginSpan;

/**
 * Simple markdown parser library: helper class
 * Span to draw lists and unordered list which align based on text (rather than the list indicator)
 * Specify margin and offset in sizable pixels (sp unit)
 */
public class AlignedListSpan implements LeadingMarginSpan {

    // --
    // Members
    // --

    private final String listToken;
    private final int margin;
    private final int offset;


    // --
    // Initialization
    // --

    public AlignedListSpan(String listToken, int margin, int offset) {
        float sp = Resources.getSystem().getDisplayMetrics().scaledDensity;
        this.listToken = listToken;
        this.margin = (int)(margin * sp);
        this.offset = (int)(offset * sp);
    }


    // --
    // Implementation
    // --

    @Override
    public int getLeadingMargin(boolean first) {
        return margin;
    }

    @Override
    public void drawLeadingMargin(Canvas canvas, Paint paint, int x, int dir, int top, int baseline, int bottom, CharSequence text, int start, int end, boolean first, Layout layout) {
        if (first) {
            // Abort when not starting at the start of the span (fixes forced new lines in the text)
            int spanStart = start;
            if (text instanceof Spanned) {
                spanStart = ((Spanned)text).getSpanStart(this);
            }
            if (start > spanStart) {
                return;
            }

            // Continue drawing
            Paint.Style orgStyle = paint.getStyle();
            paint.setStyle(Paint.Style.FILL);
            canvas.drawText(listToken, x + getLeadingMargin(true) - offset - paint.measureText(listToken), baseline, paint);
            paint.setStyle(orgStyle);
        }
    }
}
