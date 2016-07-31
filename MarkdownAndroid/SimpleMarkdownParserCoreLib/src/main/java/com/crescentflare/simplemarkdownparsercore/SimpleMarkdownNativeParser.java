package com.crescentflare.simplemarkdownparsercore;

/**
 * Simple markdown parser core library: native parser implementation
 * Parses the markdown data in fast native code (useful for big documents)
 */
public class SimpleMarkdownNativeParser implements SimpleMarkdownParser
{
    /**
     * Import native library
     */
    static
    {
        System.loadLibrary("simplemarkdownparser_native");
    }

    /**
     * Definitions for native info
     */
    private static int NATIVE_INFO_START_POSITION = 0;
    private static int NATIVE_INFO_END_POSITION = 1;
    private static int NATIVE_INFO_START_TEXT = 2;
    private static int NATIVE_INFO_END_TEXT = 3;
    private static int NATIVE_INFO_START_EXTRA = 4;
    private static int NATIVE_INFO_END_EXTRA = 5;

    /**
     * Wrapper for finding markdown tags natively, most of the work is being done in the C source file
     */
    public MarkdownTag[] findTags(String markdownText)
    {
        int[] nativeTags = findNativeTags(markdownText);
        int count = getTagCount(nativeTags);
        if (count > 0)
        {
            MarkdownTag[] tags = new MarkdownTag[count];
            for (int i = 0; i < count; i++)
            {
                tags[i] = getConvertedTag(nativeTags, i);
            }
            return tags;
        }
        return new MarkdownTag[0];
    }

    private native int[] findNativeTags(String markdownText);

    /**
     * Convert tags from native int array to java object
     */
    private static final int FIELD_COUNT = 15;

    private int getTagCount(final int[] nativeTags)
    {
        if (nativeTags == null)
        {
            return 0;
        }
        return nativeTags.length / FIELD_COUNT;
    }

    private MarkdownTag getConvertedTag(final int[] nativeTags, int position)
    {
        MarkdownTag tag = new MarkdownTag();
        position *= FIELD_COUNT;
        tag.type = getConvertedTagType(nativeTags[position]);
        tag.flags = nativeTags[position + 1];
        tag.weight = nativeTags[position + 2];
        tag.startPosition = nativeTags[position + 3];
        tag.endPosition = nativeTags[position + 4];
        tag.startText = nativeTags[position + 5];
        tag.endText = nativeTags[position + 6];
        tag.startExtra = nativeTags[position + 7];
        tag.endExtra = nativeTags[position + 8];
        tag.nativeInfo = new int[6];
        tag.nativeInfo[NATIVE_INFO_START_POSITION] = nativeTags[position + 9];
        tag.nativeInfo[NATIVE_INFO_END_POSITION] = nativeTags[position + 10];
        tag.nativeInfo[NATIVE_INFO_START_TEXT] = nativeTags[position + 11];
        tag.nativeInfo[NATIVE_INFO_END_TEXT] = nativeTags[position + 12];
        tag.nativeInfo[NATIVE_INFO_START_EXTRA] = nativeTags[position + 13];
        tag.nativeInfo[NATIVE_INFO_END_EXTRA] = nativeTags[position + 14];
        return tag;
    }

    private MarkdownTag.Type getConvertedTagType(int nativeEnumValue)
    {
        switch (nativeEnumValue)
        {
            case 1:
                return MarkdownTag.Type.Normal;
            case 2:
                return MarkdownTag.Type.Paragraph;
            case 3:
                return MarkdownTag.Type.TextStyle;
            case 4:
                return MarkdownTag.Type.AlternativeTextStyle;
            case 5:
                return MarkdownTag.Type.Link;
            case 6:
                return MarkdownTag.Type.Header;
            case 7:
                return MarkdownTag.Type.OrderedList;
            case 8:
                return MarkdownTag.Type.UnorderedList;
        }
        return MarkdownTag.Type.Normal;
    }

    /**
     * Extract markdown text components
     */
    public String extractText(String markdownText, MarkdownTag tag)
    {
        if ((tag.flags & MarkdownTag.FLAG_ESCAPED) > 0)
        {
            if (tag.nativeInfo != null)
            {
                return escapedSubstring(markdownText, tag.nativeInfo[NATIVE_INFO_START_TEXT], tag.endText - tag.startText);
            }
            return escapedSubstringJava(markdownText, tag.startText, tag.endText);
        }
        return markdownText.substring(tag.startText, tag.endText);
    }

    public String extractTextBetween(String markdownText, MarkdownTag startTag, MarkdownTag endTag, ExtractBetweenMode mode)
    {
        int startPos = 0, endPos = 0;
        switch (mode)
        {
            case StartToNext:
                startPos = startTag.startText;
                endPos = endTag.startPosition;
                break;
            case IntermediateToNext:
                startPos = startTag.endPosition;
                endPos = endTag.startPosition;
                break;
            case IntermediateToEnd:
                startPos = startTag.endPosition;
                endPos = endTag.endText;
                break;
        }
        if (startPos >= endPos)
        {
            return "";
        }
        if ((startTag.flags & MarkdownTag.FLAG_ESCAPED) > 0)
        {
            if (startTag.nativeInfo != null)
            {
                int startNativePos = 0;
                switch (mode)
                {
                    case StartToNext:
                        startNativePos = startTag.nativeInfo[NATIVE_INFO_START_TEXT];
                        break;
                    case IntermediateToNext:
                    case IntermediateToEnd:
                        startNativePos = startTag.nativeInfo[NATIVE_INFO_END_POSITION];
                        break;
                }
                return escapedSubstring(markdownText, startNativePos, endPos - startPos);
            }
            return escapedSubstringJava(markdownText, startPos, endPos);
        }
        return markdownText.substring(startPos, endPos);
    }

    public String extractFull(String markdownText, MarkdownTag tag)
    {
        if ((tag.flags & MarkdownTag.FLAG_ESCAPED) > 0)
        {
            if (tag.nativeInfo != null)
            {
                return escapedSubstring(markdownText, tag.nativeInfo[NATIVE_INFO_START_POSITION], tag.endPosition - tag.startPosition);
            }
            return escapedSubstringJava(markdownText, tag.startPosition, tag.endPosition);
        }
        return markdownText.substring(tag.startPosition, tag.endPosition);
    }

    public String extractFullBetween(String markdownText, MarkdownTag startTag, MarkdownTag endTag, ExtractBetweenMode mode)
    {
        int startPos = 0, endPos = 0;
        switch (mode)
        {
            case StartToNext:
                startPos = startTag.startPosition;
                endPos = endTag.startPosition;
                break;
            case IntermediateToNext:
                startPos = startTag.endPosition;
                endPos = endTag.startPosition;
                break;
            case IntermediateToEnd:
                startPos = startTag.endPosition;
                endPos = endTag.endPosition;
                break;
        }
        if (startPos >= endPos)
        {
            return "";
        }
        if ((startTag.flags & MarkdownTag.FLAG_ESCAPED) > 0)
        {
            if (startTag.nativeInfo != null)
            {
                int startNativePos = 0;
                switch (mode)
                {
                    case StartToNext:
                        startNativePos = startTag.nativeInfo[NATIVE_INFO_START_POSITION];
                        break;
                    case IntermediateToNext:
                    case IntermediateToEnd:
                        startNativePos = startTag.nativeInfo[NATIVE_INFO_END_POSITION];
                        break;
                }
                return escapedSubstring(markdownText, startNativePos, endPos - startPos);
            }
            return escapedSubstringJava(markdownText, startPos, endPos);
        }
        return markdownText.substring(startPos, endPos);
    }

    public String extractExtra(String markdownText, MarkdownTag tag)
    {
        if (tag.startExtra < 0 || tag.endExtra < 0 || tag.endExtra <= tag.startExtra)
        {
            return "";
        }
        if ((tag.flags & MarkdownTag.FLAG_ESCAPED) > 0)
        {
            if (tag.nativeInfo != null)
            {
                return escapedSubstring(markdownText, tag.nativeInfo[NATIVE_INFO_START_EXTRA], tag.nativeInfo[NATIVE_INFO_END_EXTRA]);
            }
            return escapedSubstringJava(markdownText, tag.startExtra, tag.endExtra);
        }
        return markdownText.substring(tag.startExtra, tag.endExtra);
    }

    private native String escapedSubstring(String text, int bytePosition, int length);

    private String escapedSubstringJava(String text, int startPosition, int endPosition)
    {
        String filteredText = "";
        for (int i = startPosition; i < endPosition; i++)
        {
            char chr = text.charAt(i);
            if (chr == '\\' && text.charAt(i + 1) != '\n')
            {
                filteredText += text.charAt(i + 1);
                i++;
                continue;
            }
            filteredText += chr;
        }
        return filteredText;
    }
}
