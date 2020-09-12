package com.crescentflare.simplemarkdownparser.core;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * Simple markdown parser core library: java parser implementation
 * Parses the markdown data in java (if speed is not important or if the document is very small)
 */
public class SimpleMarkdownJavaParser implements SimpleMarkdownParser
{
    /**
     * Public function to find all supported markdown tags
     */
    public MarkdownTag[] findTags(String markdownText)
    {
        final List<MarkdownTag> foundTags = new ArrayList<>();
        final int maxLength = markdownText.length();
        int paragraphStartPos = -1;
        MarkdownTag curLine = scanLine(markdownText, 0, maxLength, MarkdownTag.Type.Paragraph);
        while (curLine != null)
        {
            //Fetch next line ahead
            boolean hasNextLine = curLine.endPosition < maxLength;
            boolean isEmptyLine = curLine.startPosition + 1 == curLine.endPosition;
            MarkdownTag.Type curType = curLine.type;
            if (isEmptyLine)
            {
                curType = MarkdownTag.Type.Paragraph;
            }
            MarkdownTag nextLine = hasNextLine ? scanLine(markdownText, curLine.endPosition, maxLength, curType) : null;

            //Insert section tag
            if (curLine.startText >= 0)
            {
                addStyleTags(foundTags, markdownText, curLine);
            }
            else if (!isEmptyLine)
            {
                MarkdownTag spacedLineTag = new MarkdownTag();
                spacedLineTag.type = curLine.type;
                spacedLineTag.startPosition = curLine.startPosition;
                spacedLineTag.endPosition = curLine.endPosition;
                spacedLineTag.startText = curLine.startPosition;
                spacedLineTag.endText = curLine.startPosition;
                spacedLineTag.weight = curLine.weight;
                spacedLineTag.flags = curLine.flags;
                foundTags.add(spacedLineTag);
            }

            //Insert paragraphs when needed
            if (nextLine != null)
            {
                boolean startNewParagraph = curLine.type == MarkdownTag.Type.Header || nextLine.type == MarkdownTag.Type.Header || nextLine.startPosition + 1 == nextLine.endPosition;
                boolean stopParagraph = nextLine.startPosition + 1 != nextLine.endPosition;
                if (startNewParagraph && foundTags.size() > 0 && paragraphStartPos < 0)
                {
                    paragraphStartPos = curLine.endPosition;
                }
                if (stopParagraph && paragraphStartPos >= 0)
                {
                    MarkdownTag paragraphTag = new MarkdownTag();
                    paragraphTag.type = MarkdownTag.Type.Paragraph;
                    paragraphTag.startPosition = paragraphStartPos;
                    paragraphTag.endPosition = nextLine.startPosition;
                    paragraphTag.startText = paragraphStartPos;
                    paragraphTag.endText = paragraphStartPos;
                    paragraphTag.weight = nextLine.type == MarkdownTag.Type.Header ? 2 : 1;
                    foundTags.add(paragraphTag);
                    paragraphStartPos = -1;
                }
            }

            //Set pointer to next line and continue
            curLine = nextLine;
        }
        return foundTags.toArray(new MarkdownTag[foundTags.size()]);
    }

    /**
     * Extract markdown text components
     */
    public String extractText(String markdownText, MarkdownTag tag)
    {
        if ((tag.flags & MarkdownTag.FLAG_ESCAPED) > 0)
        {
            return escapedSubstring(markdownText, tag.startText, tag.endText);
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
            return escapedSubstring(markdownText, startPos, endPos);
        }
        return markdownText.substring(startPos, endPos);
    }

    public String extractFull(String markdownText, MarkdownTag tag)
    {
        if ((tag.flags & MarkdownTag.FLAG_ESCAPED) > 0)
        {
            return escapedSubstring(markdownText, tag.startPosition, tag.endPosition);
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
            return escapedSubstring(markdownText, startPos, endPos);
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
            return escapedSubstring(markdownText, tag.startExtra, tag.endExtra);
        }
        return markdownText.substring(tag.startExtra, tag.endExtra);
    }

    private String escapedSubstring(String text, int startPosition, int endPosition)
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

    /**
     * Scan a single line of text within the markdown document, return section tag
     */
    private MarkdownTag scanLine(final String markdownText, int position, int maxLength, MarkdownTag.Type sectionType)
    {
        if (position >= maxLength)
        {
            return null;
        }
        MarkdownTag styledTag = new MarkdownTag();
        MarkdownTag normalTag = new MarkdownTag();
        int skipChars = 0;
        char chr = 0, nextChr = markdownText.charAt(position), secondNextChr = 0;
        boolean styleTagDefined = false, escaped = false;
        boolean headerTokenSequence = false;
        if (position + 1 < maxLength)
        {
            secondNextChr = markdownText.charAt(position + 1);
        }
        normalTag.startPosition = position;
        styledTag.startPosition = position;
        for (int i = position; i < maxLength; i++)
        {
            chr = nextChr;
            nextChr = secondNextChr;
            if (i + 2 < maxLength)
            {
                secondNextChr = markdownText.charAt(i + 2);
            }
            if (skipChars > 0)
            {
                skipChars--;
                continue;
            }
            if (!escaped && chr == '\\')
            {
                normalTag.flags = normalTag.flags | MarkdownTag.FLAG_ESCAPED;
                styledTag.flags = styledTag.flags | MarkdownTag.FLAG_ESCAPED;
                escaped = true;
                continue;
            }
            if (escaped)
            {
                if (chr != '\n')
                {
                    if (normalTag.startText < 0)
                    {
                        normalTag.startText = i;
                    }
                    if (styledTag.startText < 0)
                    {
                        styledTag.startText = i;
                    }
                }
                normalTag.endText = i + 1;
                styledTag.endText = i + 1;
            }
            else
            {
                if (chr == '\n')
                {
                    normalTag.endPosition = i + 1;
                    styledTag.endPosition = i + 1;
                    break;
                }
                if (chr != ' ')
                {
                    if (normalTag.startText < 0)
                    {
                        normalTag.startText = i;
                    }
                    normalTag.endText = i + 1;
                }
                if (!styleTagDefined)
                {
                    boolean allowNewParagraph = sectionType == MarkdownTag.Type.Paragraph || sectionType == MarkdownTag.Type.Header;
                    boolean continueBulletList = sectionType == MarkdownTag.Type.UnorderedList || sectionType == MarkdownTag.Type.OrderedList;
                    if (chr == '#')
                    {
                        styledTag.type = MarkdownTag.Type.Header;
                        styledTag.weight = 1;
                        styleTagDefined = true;
                        headerTokenSequence = true;
                    }
                    else if ((allowNewParagraph || continueBulletList) && (chr == '*' || chr == '-' || chr == '+') && nextChr == ' ' && (i - position) % 2 == 0)
                    {
                        styledTag.type = MarkdownTag.Type.UnorderedList;
                        styledTag.weight = 1 + (i - position) / 2;
                        styleTagDefined = true;
                        skipChars = 1;
                    }
                    else if ((allowNewParagraph || continueBulletList) && chr >= '0' && chr <= '9' && nextChr == '.' && secondNextChr == ' ' && (i - position) % 2 == 0)
                    {
                        styledTag.type = MarkdownTag.Type.OrderedList;
                        styledTag.weight = 1 + (i - position) / 2;
                        styleTagDefined = true;
                        skipChars = 2;
                    }
                    else if (chr != ' ')
                    {
                        styledTag.type = MarkdownTag.Type.Normal;
                        styleTagDefined = true;
                    }
                }
                else if (styledTag.type != MarkdownTag.Type.Normal)
                {
                    if (styledTag.type == MarkdownTag.Type.Header)
                    {
                        if (chr == '#' && headerTokenSequence)
                        {
                            styledTag.weight++;
                        }
                        else
                        {
                            headerTokenSequence = false;
                        }
                        if (chr != '#' && chr != ' ' && styledTag.startText < 0)
                        {
                            styledTag.startText = i;
                            styledTag.endText = i + 1;
                        }
                        else if ((chr != '#' || (nextChr != '#' && nextChr != '\n' && nextChr != ' ' && nextChr != 0)) && chr != ' ' && styledTag.startText >= 0)
                        {
                            styledTag.endText = i + 1;
                        }
                    }
                    else
                    {
                        if (chr != ' ')
                        {
                            if (styledTag.startText < 0)
                            {
                                styledTag.startText = i;
                            }
                            styledTag.endText = i + 1;
                        }
                    }
                }
            }
            escaped = false;
        }
        if (styleTagDefined && styledTag.type != MarkdownTag.Type.Normal && styledTag.startText >= 0 && styledTag.endText > styledTag.startText)
        {
            if (styledTag.endPosition < 0)
            {
                styledTag.endPosition = maxLength;
            }
            return styledTag;
        }
        if (normalTag.endPosition < 0)
        {
            normalTag.endPosition = maxLength;
        }
        normalTag.type = MarkdownTag.Type.Normal;
        return normalTag;
    }

    /**
     * Add the section tag and add additional tags within the section
     */
    private void addStyleTags(final List<MarkdownTag> foundTags, final String markdownText, final MarkdownTag sectionTag)
    {
        //First add the main section tag
        MarkdownTag mainTag = new MarkdownTag();
        mainTag.type = sectionTag.type;
        mainTag.startPosition = sectionTag.startPosition;
        mainTag.endPosition = sectionTag.endPosition;
        mainTag.startText = sectionTag.startText;
        mainTag.endText = sectionTag.endText;
        mainTag.weight = sectionTag.weight;
        mainTag.flags = sectionTag.flags;
        foundTags.add(mainTag);

        //Traverse string and find tag markers
        List<MarkdownMarker> tagMarkers = new ArrayList<>();
        List<MarkdownTag> addTags = new ArrayList<>();
        int maxLength = sectionTag.endText;
        int curMarkerWeight = 0;
        char curMarkerChar = 0;
        for (int i = sectionTag.startText; i < maxLength; i++)
        {
            char chr = markdownText.charAt(i);
            if (curMarkerChar != 0)
            {
                if (chr == curMarkerChar)
                {
                    curMarkerWeight++;
                }
                else
                {
                    tagMarkers.add(new MarkdownMarker(curMarkerChar, curMarkerWeight, i - curMarkerWeight));
                    curMarkerChar = 0;
                }
            }
            if (curMarkerChar == 0)
            {
                if (chr == '*' || chr == '_' || chr == '~')
                {
                    curMarkerChar = chr;
                    curMarkerWeight = 1;
                }
                else if (chr == '[' || chr == ']' || chr == '(' || chr == ')')
                {
                    tagMarkers.add(new MarkdownMarker(chr, 1, i));
                }
            }
            if (chr == '\\')
            {
                i++;
            }
        }
        if (curMarkerChar != 0)
        {
            tagMarkers.add(new MarkdownMarker(curMarkerChar, curMarkerWeight, maxLength - curMarkerWeight));
        }

        //Sort tags to add and finally add them
        processMarkers(addTags, tagMarkers, 0, tagMarkers.size(), sectionTag.flags);
        Collections.sort(addTags, new Comparator<MarkdownTag>()
        {
            @Override
            public int compare(MarkdownTag lhs, MarkdownTag rhs)
            {
                return lhs.startPosition - rhs.startPosition;
            }
        });
        foundTags.addAll(addTags);
    }

    /**
     * Recursive function to process markdown markers into tags
     */
    private void processMarkers(final List<MarkdownTag> addTags, final List<MarkdownMarker> markers, int start, final int end, final int addFlags)
    {
        boolean processing = true;
        while (processing && start < end)
        {
            MarkdownMarker marker = markers.get(start);
            processing = false;
            if (marker.chr == '[' || marker.chr == ']' || marker.chr == '(' || marker.chr == ')')
            {
                if (marker.chr == '[')
                {
                    MarkdownTag linkTag = null;
                    MarkdownMarker extraMarker = null;
                    for (int i = start + 1; i < end; i++)
                    {
                        MarkdownMarker checkMarker = markers.get(i);
                        if ((checkMarker.chr == ']' && linkTag == null) || (checkMarker.chr == ')' && linkTag != null))
                        {
                            if (linkTag == null)
                            {
                                linkTag = new MarkdownTag();
                                linkTag.type = MarkdownTag.Type.Link;
                                linkTag.startPosition = marker.position;
                                linkTag.endPosition = checkMarker.position + checkMarker.weight;
                                linkTag.startText = linkTag.startPosition + marker.weight;
                                linkTag.endText = checkMarker.position;
                                linkTag.flags = addFlags;
                                addTags.add(linkTag);
                                start = i + 1;
                                if (start < end)
                                {
                                    extraMarker = markers.get(start);
                                    if (extraMarker.chr != '(' || extraMarker.position != checkMarker.position + checkMarker.weight)
                                    {
                                        processing = true;
                                        break;
                                    }
                                }
                            }
                            else if (extraMarker != null)
                            {
                                linkTag.startExtra = extraMarker.position + extraMarker.weight;
                                linkTag.endExtra = checkMarker.position;
                                linkTag.endPosition = checkMarker.position + checkMarker.weight;
                                start = i + 1;
                                processing = true;
                                break;
                            }
                        }
                    }
                }
            }
            else
            {
                for (int i = start + 1; i < end; i++)
                {
                    MarkdownMarker checkMarker = markers.get(i);
                    if (checkMarker.chr == marker.chr && checkMarker.weight >= marker.weight)
                    {
                        MarkdownTag tag = new MarkdownTag();
                        tag.type = checkMarker.chr == '~' ? MarkdownTag.Type.AlternativeTextStyle : MarkdownTag.Type.TextStyle;
                        tag.weight = marker.weight;
                        tag.startPosition = marker.position;
                        tag.endPosition = checkMarker.position + marker.weight;
                        tag.startText = tag.startPosition + marker.weight;
                        tag.endText = checkMarker.position;
                        tag.flags = addFlags;
                        addTags.add(tag);
                        processMarkers(addTags, markers, start + 1, i, addFlags);
                        if (checkMarker.weight > marker.weight)
                        {
                            checkMarker.weight -= marker.weight;
                            start = i;
                        }
                        else
                        {
                            start = i + 1;
                        }
                        processing = true;
                        break;
                    }
                }
            }
            if (!processing)
            {
                if (marker.weight > 1)
                {
                    marker.weight--;
                }
                else
                {
                    start++;
                }
                processing = true;
            }
        }
    }

    /**
     * A class containing a markdown tag marker
     */
    static class MarkdownMarker
    {
        public char chr;
        public int weight;
        public int position;

        public MarkdownMarker(char chr, int weight, int position)
        {
            this.chr = chr;
            this.weight = weight;
            this.position = position;
        }
    }
}
