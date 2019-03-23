package com.crescentflare.simplemarkdownparser;

import android.text.SpannableString;
import android.text.SpannableStringBuilder;
import android.text.Spanned;

import com.crescentflare.simplemarkdownparser.helper.DefaultMarkdownSpanGenerator;
import com.crescentflare.simplemarkdownparser.helper.MarkdownSpanGenerator;
import com.crescentflare.simplemarkdownparser.core.SimpleMarkdownJavaParser;
import com.crescentflare.simplemarkdownparser.core.SimpleMarkdownNativeParser;
import com.crescentflare.simplemarkdownparser.core.SimpleMarkdownParser;
import com.crescentflare.simplemarkdownparser.core.MarkdownTag;

import java.util.ArrayList;
import java.util.List;

/**
 * Simple markdown parser library: markdown text converter
 * Convert markdown to other formats usable for Android (like html or spannable strings)
 */
public class SimpleMarkdownConverter
{
    /**
     * Static member to determine availability of the native core parser implementation
     */
    private static int nativeParserLibraryLoaded = 0;

    /**
     * HTML conversion handling
     */
    public static String toHtmlString(String markdownText)
    {
        SimpleMarkdownParser parser = obtainParser(markdownText);
        MarkdownTag[] foundTags = parser.findTags(markdownText);
        String htmlString = "";
        List<Integer> listCount = new ArrayList<>();
        MarkdownTag.Type prevSectionType = MarkdownTag.Type.Paragraph;
        boolean addedParagraph = true;
        for (int i = 0; i < foundTags.length; i++)
        {
            MarkdownTag sectionTag = foundTags[i];
            if (!addedParagraph && sectionTag.type == MarkdownTag.Type.Normal)
            {
                htmlString += "<br/>";
            }
            if (sectionTag.type == MarkdownTag.Type.OrderedList || sectionTag.type == MarkdownTag.Type.UnorderedList)
            {
                int matchedType = sectionTag.type == MarkdownTag.Type.OrderedList ? 0 : 1;
                if (listCount.size() == sectionTag.weight && listCount.size() > 0 && listCount.get(listCount.size() - 1) != matchedType)
                {
                    htmlString += listCount.get(listCount.size() - 1) == 0 ? "</ol>" : "</ul>";
                    listCount.remove(listCount.size() - 1);
                }
                for (int j = listCount.size(); j < sectionTag.weight; j++)
                {
                    listCount.add(sectionTag.type == MarkdownTag.Type.OrderedList ? 0 : 1);
                    htmlString += sectionTag.type == MarkdownTag.Type.OrderedList ? "<ol>" : "<ul>";
                }
                for (int j = listCount.size(); j > sectionTag.weight; j--)
                {
                    htmlString += listCount.get(listCount.size() - 1) == 0 ? "</ol>" : "</ul>";
                    listCount.remove(listCount.size() - 1);
                }
            }
            if (sectionTag.type == MarkdownTag.Type.Header || sectionTag.type == MarkdownTag.Type.OrderedList || sectionTag.type == MarkdownTag.Type.UnorderedList || sectionTag.type == MarkdownTag.Type.Normal)
            {
                List<MarkdownTag> handledTags = new ArrayList<>();
                htmlString += getHtmlTag(parser, markdownText, sectionTag, false);
                htmlString = appendHtmlString(parser, handledTags, htmlString, markdownText, foundTags, i);
                htmlString += getHtmlTag(parser, markdownText, sectionTag, true);
                i += handledTags.size() - 1;
                addedParagraph = sectionTag.type != MarkdownTag.Type.Normal;
            }
            else if (sectionTag.type == MarkdownTag.Type.Paragraph)
            {
                boolean nextNormal = i + 1 < foundTags.length && foundTags[i + 1].type == MarkdownTag.Type.Normal;
                if (prevSectionType == MarkdownTag.Type.Normal && nextNormal)
                {
                    for (int j = 0; j < sectionTag.weight + 1; j++)
                    {
                        htmlString += "<br/>";
                    }
                }
                addedParagraph = true;
                for (int j = listCount.size(); j > 0; j--)
                {
                    htmlString += listCount.get(listCount.size() - 1) == 0 ? "</ol>" : "</ul>";
                    listCount.remove(listCount.size() - 1);
                }
            }
            prevSectionType = sectionTag.type;
        }
        for (int j = listCount.size(); j > 0; j--)
        {
            htmlString += listCount.get(listCount.size() - 1) == 0 ? "</ol>" : "</ul>";
            listCount.remove(listCount.size() - 1);
        }
        return htmlString;
    }

    private static String appendHtmlString(SimpleMarkdownParser parser, List<MarkdownTag> handledTags, String htmlString, String markdownText, MarkdownTag[] foundTags, int start)
    {
        MarkdownTag curTag = foundTags[start];
        MarkdownTag intermediateTag = null;
        MarkdownTag processingTag = null;
        int checkPosition = start + 1;
        boolean processing = true;
        while (processing)
        {
            MarkdownTag nextTag = checkPosition < foundTags.length ? foundTags[checkPosition] : null;
            processing = false;
            if (nextTag != null && nextTag.startPosition < curTag.endPosition)
            {
                if (processingTag == null)
                {
                    processingTag = new MarkdownTag();
                    handledTags.add(processingTag);
                    processingTag.type = curTag.type;
                    processingTag.weight = curTag.weight;
                    processingTag.startExtra = curTag.startExtra;
                    processingTag.endExtra = curTag.endExtra;
                    processingTag.startText = htmlString.length();
                    htmlString += parser.extractTextBetween(markdownText, curTag, nextTag, SimpleMarkdownParser.ExtractBetweenMode.StartToNext);
                    processingTag.endText = htmlString.length();
                }
                else
                {
                    htmlString += parser.extractTextBetween(markdownText, intermediateTag, nextTag, SimpleMarkdownParser.ExtractBetweenMode.IntermediateToNext);
                    processingTag.endText = htmlString.length();
                }
                int prevHandledTagSize = handledTags.size();
                htmlString += getHtmlTag(parser, markdownText, nextTag, false);
                htmlString = appendHtmlString(parser, handledTags, htmlString, markdownText, foundTags, checkPosition);
                htmlString += getHtmlTag(parser, markdownText, nextTag, true);
                intermediateTag = foundTags[checkPosition];
                checkPosition += handledTags.size() - prevHandledTagSize;
                processing = true;
            }
            else
            {
                if (processingTag == null)
                {
                    processingTag = new MarkdownTag();
                    handledTags.add(processingTag);
                    processingTag.type = curTag.type;
                    processingTag.weight = curTag.weight;
                    processingTag.startExtra = curTag.startExtra;
                    processingTag.endExtra = curTag.endExtra;
                    processingTag.startText = htmlString.length();
                    htmlString += parser.extractText(markdownText, curTag);
                    processingTag.endText = htmlString.length();
                }
                else
                {
                    htmlString += parser.extractTextBetween(markdownText, intermediateTag, curTag, SimpleMarkdownParser.ExtractBetweenMode.IntermediateToEnd);
                    processingTag.endText = htmlString.length();
                }
            }
        }
        return htmlString;
    }

    private static String getHtmlTag(SimpleMarkdownParser parser, String markdownText, MarkdownTag tag, boolean closingTag)
    {
        String start = closingTag ? "</" : "<";
        if (tag.type == MarkdownTag.Type.TextStyle)
        {
            switch (tag.weight)
            {
                case 1:
                    start += "i";
                    break;
                case 2:
                    start += "b";
                    break;
                case 3:
                    if (closingTag)
                    {
                        start += "b>" + start + "i";
                    }
                    else
                    {
                        start += "i>" + start + "b";
                    }
                    break;
            }
        }
        else if (tag.type == MarkdownTag.Type.AlternativeTextStyle)
        {
            start += "strike";
        }
        else if (tag.type == MarkdownTag.Type.Header)
        {
            int headerSize = 6;
            if (tag.weight >= 1 && tag.weight < 7)
            {
                headerSize = tag.weight;
            }
            start += "h" + headerSize;
        }
        else if (tag.type == MarkdownTag.Type.OrderedList || tag.type == MarkdownTag.Type.UnorderedList)
        {
            start += "li";
        }
        else if (tag.type == MarkdownTag.Type.Link)
        {
            start += "a";
            if (!closingTag)
            {
                String linkLocation = parser.extractExtra(markdownText, tag);
                if (linkLocation.length() == 0)
                {
                    linkLocation = parser.extractText(markdownText, tag);
                }
                int spacePos = linkLocation.indexOf(' ');
                if (spacePos >= 0)
                {
                    linkLocation = linkLocation.substring(0, spacePos);
                }
                start += " href=" + linkLocation;
            }
        }
        else
        {
            return "";
        }
        return start + ">";
    }

    /**
     * Spannable conversion handling
     */
    public static Spanned toSpannable(String markdownText)
    {
        return toSpannable(markdownText, new DefaultMarkdownSpanGenerator());
    }

    public static Spanned toSpannable(String markdownText, MarkdownSpanGenerator spanGenerator)
    {
        if (spanGenerator == null)
        {
            return new SpannableString("#Error");
        }
        SimpleMarkdownParser parser = obtainParser(markdownText);
        MarkdownTag[] foundTags = parser.findTags(markdownText);
        SpannableStringBuilder builder = new SpannableStringBuilder();
        List<Integer> listCount = new ArrayList<>();
        boolean addedParagraph = true;
        for (int i = 0; i < foundTags.length; i++)
        {
            MarkdownTag sectionTag = foundTags[i];
            if (!addedParagraph)
            {
                builder.append("\n");
            }
            if (sectionTag.type == MarkdownTag.Type.OrderedList || sectionTag.type == MarkdownTag.Type.UnorderedList)
            {
                for (int j = listCount.size(); j < sectionTag.weight; j++)
                {
                    listCount.add(0);
                }
                for (int j = listCount.size(); j > sectionTag.weight; j--)
                {
                    listCount.remove(listCount.size() - 1);
                }
                if (sectionTag.type == MarkdownTag.Type.OrderedList)
                {
                    listCount.set(listCount.size() - 1, listCount.get(listCount.size() - 1) + 1);
                }
            }
            if (sectionTag.type == MarkdownTag.Type.Header || sectionTag.type == MarkdownTag.Type.OrderedList || sectionTag.type == MarkdownTag.Type.UnorderedList || sectionTag.type == MarkdownTag.Type.Normal)
            {
                List<MarkdownTag> convertedTags = new ArrayList<>();
                appendSpannableBuilder(parser, convertedTags, builder, markdownText, foundTags, i);
                i += convertedTags.size() - 1;
                if (sectionTag.type == MarkdownTag.Type.OrderedList || sectionTag.type == MarkdownTag.Type.UnorderedList)
                {
                    String token = spanGenerator.getListToken(sectionTag.type, sectionTag.weight, listCount.get(listCount.size() - 1));
                    if (token == null)
                    {
                        token = "";
                    }
                    spanGenerator.applySpan(builder, sectionTag.type, sectionTag.weight, convertedTags.get(0).startText, convertedTags.get(0).endText, token);
                }
                for (MarkdownTag tag : convertedTags)
                {
                    if (tag.type == MarkdownTag.Type.OrderedList || tag.type == MarkdownTag.Type.UnorderedList)
                    {
                        continue;
                    }
                    String extra = "";
                    if (tag.type == MarkdownTag.Type.Link)
                    {
                        extra = parser.extractExtra(markdownText, tag);
                        if (extra.length() == 0)
                        {
                            extra = builder.subSequence(tag.startText, tag.endText).toString();
                        }
                        int spacePos = extra.indexOf(' ');
                        if (spacePos >= 0)
                        {
                            extra = extra.substring(0, spacePos);
                        }
                    }
                    spanGenerator.applySpan(builder, tag.type, tag.weight, tag.startText, tag.endText, extra);
                }
                addedParagraph = false;
            }
            else if (sectionTag.type == MarkdownTag.Type.Paragraph)
            {
                if (sectionTag.weight > 0)
                {
                    builder.append("\n");
                    spanGenerator.applySpan(builder, MarkdownTag.Type.Paragraph, sectionTag.weight, builder.length() - 1, builder.length(), "");
                }
                addedParagraph = true;
                listCount.clear();
            }
        }
        return builder;
    }

    private static void appendSpannableBuilder(SimpleMarkdownParser parser, List<MarkdownTag> convertedTags, SpannableStringBuilder builder, String markdownText, MarkdownTag[] foundTags, int start)
    {
        MarkdownTag curTag = foundTags[start];
        MarkdownTag intermediateTag = null;
        MarkdownTag processingTag = null;
        int checkPosition = start + 1;
        boolean processing = true;
        while (processing)
        {
            MarkdownTag nextTag = checkPosition < foundTags.length ? foundTags[checkPosition] : null;
            processing = false;
            if (nextTag != null && nextTag.startPosition < curTag.endPosition)
            {
                if (processingTag == null)
                {
                    processingTag = new MarkdownTag();
                    convertedTags.add(processingTag);
                    processingTag.type = curTag.type;
                    processingTag.weight = curTag.weight;
                    processingTag.startExtra = curTag.startExtra;
                    processingTag.endExtra = curTag.endExtra;
                    processingTag.startText = builder.length();
                    builder.append(parser.extractTextBetween(markdownText, curTag, nextTag, SimpleMarkdownParser.ExtractBetweenMode.StartToNext));
                    processingTag.endText = builder.length();
                }
                else
                {
                    builder.append(parser.extractTextBetween(markdownText, intermediateTag, nextTag, SimpleMarkdownParser.ExtractBetweenMode.IntermediateToNext));
                    processingTag.endText = builder.length();
                }
                int prevConvertedTagSize = convertedTags.size();
                appendSpannableBuilder(parser, convertedTags, builder, markdownText, foundTags, checkPosition);
                intermediateTag = foundTags[checkPosition];
                checkPosition += convertedTags.size() - prevConvertedTagSize;
                processing = true;
            }
            else
            {
                if (processingTag == null)
                {
                    processingTag = new MarkdownTag();
                    convertedTags.add(processingTag);
                    processingTag.type = curTag.type;
                    processingTag.weight = curTag.weight;
                    processingTag.startExtra = curTag.startExtra;
                    processingTag.endExtra = curTag.endExtra;
                    processingTag.startText = builder.length();
                    builder.append(parser.extractText(markdownText, curTag));
                    processingTag.endText = builder.length();
                }
                else
                {
                    builder.append(parser.extractTextBetween(markdownText, intermediateTag, curTag, SimpleMarkdownParser.ExtractBetweenMode.IntermediateToEnd));
                    processingTag.endText = builder.length();
                }
            }
        }
    }

    /**
     * Obtain parser instance based on requirements
     */
    private static SimpleMarkdownParser obtainParser(String text)
    {
        if (nativeParserLibraryLoaded == 0)
        {
            try
            {
                System.loadLibrary("simplemarkdownparser_native");
                nativeParserLibraryLoaded = 1;
            }
            catch (Throwable t)
            {
                nativeParserLibraryLoaded = -1;
            }
        }
        return text.length() > 128 && nativeParserLibraryLoaded == 1 ? new SimpleMarkdownNativeParser() : new SimpleMarkdownJavaParser();
    }
}
