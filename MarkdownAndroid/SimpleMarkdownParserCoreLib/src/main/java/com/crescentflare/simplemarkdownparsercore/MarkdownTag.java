package com.crescentflare.simplemarkdownparsercore;

/**
 * Simple markdown parser core library: markdown tag
 * Used to indicate a piece of text within the given string being formatted by a markdown tag
 */
public class MarkdownTag
{
    public enum Type
    {
        Normal,
        Paragraph,
        TextStyle,
        AlternativeTextStyle,
        Link,
        Header,
        OrderedList,
        UnorderedList
    }

    public static final int FLAG_NONE = 0x0;
    public static final int FLAG_ESCAPED = 0x40000000;

    public Type type = Type.Normal;
    public int flags = FLAG_NONE;
    public int startPosition = -1;
    public int endPosition = -1;
    public int startText = -1;
    public int endText = -1;
    public int startExtra = -1;
    public int endExtra = -1;
    public int weight = 0;
    public int nativeInfo[] = null;
}
