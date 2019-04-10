package com.crescentflare.simplemarkdownparser.helper;

import android.content.res.Resources;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.text.Layout;
import android.text.style.LeadingMarginSpan;

/**
 * Simple markdown parser library: helper class
 * Span to draw lists and unordered list which align based on text (rather than the list indicator)
 * Specify margin and offset in sizable pixels (sp unit)
 */
public class AlignedListSpan implements LeadingMarginSpan
{
    private String listToken = "";
    private int margin = 0;
    private int offset = 0;

    public AlignedListSpan(String listToken, int margin, int offset)
    {
        float sp = Resources.getSystem().getDisplayMetrics().scaledDensity;
        this.listToken = listToken;
        this.margin = (int)(margin * sp);
        this.offset = (int)(offset * sp);
    }

    @Override
    public int getLeadingMargin(boolean first)
    {
        return margin;
    }

    @Override
    public void drawLeadingMargin(Canvas c, Paint p, int x, int dir, int top, int baseline, int bottom, CharSequence text, int start, int end, boolean first, Layout layout)
    {
        if (first)
        {
            Paint.Style orgStyle = p.getStyle();
            p.setStyle(Paint.Style.FILL);
            c.drawText(listToken, x + getLeadingMargin(true) - offset - p.measureText(listToken), baseline, p);
            p.setStyle(orgStyle);
        }
    }
}
