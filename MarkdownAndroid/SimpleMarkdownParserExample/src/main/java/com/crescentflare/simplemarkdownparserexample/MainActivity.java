package com.crescentflare.simplemarkdownparserexample;

import android.content.res.Resources;
import android.graphics.Typeface;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.text.Html;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.TextUtils;
import android.text.method.LinkMovementMethod;
import android.text.style.AbsoluteSizeSpan;
import android.text.style.RelativeSizeSpan;
import android.text.style.StrikethroughSpan;
import android.text.style.StyleSpan;
import android.text.style.URLSpan;
import android.widget.TextView;

import com.crescentflare.simplemarkdownparser.conversion.SimpleMarkdownConverter;
import com.crescentflare.simplemarkdownparser.helper.AlignedListSpan;
import com.crescentflare.simplemarkdownparser.conversion.MarkdownSpanGenerator;
import com.crescentflare.simplemarkdownparser.tagfinder.MarkdownTag;


/**
 * The example activity displays an example of parsed markdown
 */
public class MainActivity extends AppCompatActivity {

    // --
    // Enable/disable conversion through HTML
    // Note: HTML doesn't support ordered and unordered lists without a custom tag handler
    // --

    static final boolean TEST_HTML = false;


    // --
    // Enable/disable custom styling (if HTML is disabled above)
    // --

    static final boolean TEST_CUSTOM_STYLING = false;


    // --
    // Main sample
    // --

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        final String markdownText = TextUtils.join("\n", getResources().getStringArray(R.array.markdown_test));
        final TextView markdownView = findViewById(R.id.activity_main_text);
        if (TEST_HTML) {
            testHtml(markdownView, markdownText);
        } else {
            if (TEST_CUSTOM_STYLING) {
                testCustomStyling(markdownView, markdownText);
            } else {
                testDefaultSpanConversion(markdownView, markdownText);
            }
        }
        markdownView.setMovementMethod(LinkMovementMethod.getInstance());
    }


    // --
    // Tests
    // --

    private void testHtml(final TextView markdownView, final String markdownText) {
        String htmlString = SimpleMarkdownConverter.toHtmlString(markdownText);
        markdownView.setText(Html.fromHtml(htmlString), TextView.BufferType.SPANNABLE);
    }

    private void testCustomStyling(final TextView markdownView, final String markdownText) {
        markdownView.setText(SimpleMarkdownConverter.toSpannable(markdownText, new MarkdownSpanGenerator()
        {
            @Override
            public void applySpan(SpannableStringBuilder builder, MarkdownTag.Type type, int weight, int start, int end, String extra) {
                switch (type) {
                    case Header:
                        builder.setSpan(new RelativeSizeSpan(2 - weight * 0.15f), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                        break;
                    case OrderedListItem:
                    case UnorderedListItem:
                        builder.setSpan(new AlignedListSpan(extra, 20 + (weight - 1) * 10, 8), start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                        break;
                    case TextStyle: {
                        int textStyle = Typeface.NORMAL;
                        switch (weight) {
                            case 1:
                                textStyle = Typeface.ITALIC;
                                break;
                            case 2:
                                textStyle = Typeface.BOLD;
                                break;
                            case 3:
                                textStyle = Typeface.BOLD_ITALIC;
                                break;
                        }
                        builder.setSpan(new StyleSpan(textStyle), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                        break;
                    }
                    case AlternativeTextStyle:
                        builder.setSpan(new StrikethroughSpan(), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                        break;
                    case Link:
                        builder.setSpan(new URLSpan(extra), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                        break;
                }
            }

            public void applySectionSpacerSpan(SpannableStringBuilder builder, MarkdownTag.Type previousSectionType, int previousSectionWeight, MarkdownTag.Type nextSectionType, int nextSectionWeight, int start, int end) {
                int spacing = nextSectionType == MarkdownTag.Type.Header && previousSectionType != MarkdownTag.Type.Header ? 20 : 12;
                builder.setSpan(new AbsoluteSizeSpan((int)(Resources.getSystem().getDisplayMetrics().density * spacing)), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            }

            @Override
            public String getListToken(MarkdownTag.Type type, int weight, int index) {
                StringBuilder token = new StringBuilder();
                if (type == MarkdownTag.Type.OrderedListItem) {
                    for (int i = 0; i < index; i++) {
                        token.append("i");
                    }
                    token.append(".");
                } else {
                    for (int i = 0; i < weight; i++) {
                        token.append(">");
                    }
                }
                return token.toString();
            }
        }), TextView.BufferType.SPANNABLE);
    }

    private void testDefaultSpanConversion(final TextView markdownView, final String markdownText) {
        markdownView.setText(SimpleMarkdownConverter.toSpannable(markdownText), TextView.BufferType.SPANNABLE);
    }
}
