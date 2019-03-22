#include <jni.h>
#include <stdlib.h>
#include <algorithm>
#include <vector>
#include <cstring>
#include "utfstring.h"

/**
 * Constants, enum, struct and utility functions for markdown tags
 */
static const int MARKDOWN_FLAG_NONE = 0x0;
static const int MARKDOWN_FLAG_ESCAPED = 0x40000000;

typedef enum
{
    MARKDOWN_TAG_INVALID = 0,
    MARKDOWN_TAG_NORMAL,
    MARKDOWN_TAG_PARAGRAPH,
    MARKDOWN_TAG_TEXTSTYLE,
    MARKDOWN_TAG_ALTERNATIVE_TEXTSTYLE,
    MARKDOWN_TAG_LINK,
    MARKDOWN_TAG_HEADER,
    MARKDOWN_TAG_ORDERED_LIST,
    MARKDOWN_TAG_UNORDERED_LIST
}MARKDOWN_TAG_TYPE;

class MarkdownTag
{
public:
    MARKDOWN_TAG_TYPE type = MARKDOWN_TAG_INVALID;
    int flags = 0;
    UTFStringIndex startPosition = UTFStringIndex(nullptr);
    UTFStringIndex endPosition = UTFStringIndex(nullptr);
    UTFStringIndex startText = UTFStringIndex(nullptr);
    UTFStringIndex endText = UTFStringIndex(nullptr);
    UTFStringIndex startExtra = UTFStringIndex(nullptr);
    UTFStringIndex endExtra = UTFStringIndex(nullptr);
    int weight = 1;
public:
    bool valid()
    {
        return type != MARKDOWN_TAG_INVALID;
    }
};

class MarkdownMarker
{
public:
    int chr;
    int weight;
    UTFStringIndex position;
public:
    MarkdownMarker() : chr(0), weight(0), position(nullptr) { }
    MarkdownMarker(int chr, int weight, UTFStringIndex position) : chr(chr), weight(weight), position(position){ }
    bool valid()
    {
        return position.valid();
    }
};

const unsigned char tagFieldCount()
{
    return 15;
}

void fillTagToArray(const MarkdownTag *tag, jint *ptr)
{
    if (tag && ptr)
    {
        ptr[0] = tag->type;
        ptr[1] = tag->flags;
        ptr[2] = tag->weight;
        ptr[3] = tag->startPosition.chrPos;
        ptr[4] = tag->endPosition.chrPos;
        ptr[5] = tag->startText.chrPos;
        ptr[6] = tag->endText.chrPos;
        ptr[7] = tag->startExtra.chrPos;
        ptr[8] = tag->endExtra.chrPos;
        ptr[9] = tag->startPosition.bytePos;
        ptr[10] = tag->endPosition.bytePos;
        ptr[11] = tag->startText.bytePos;
        ptr[12] = tag->endText.bytePos;
        ptr[13] = tag->startExtra.bytePos;
        ptr[14] = tag->endExtra.bytePos;
    }
}


/**
 * Recursive function to process markdown markers into tags
 */
void processMarkers(std::vector<MarkdownTag> &addTags, std::vector<MarkdownMarker> &markers, int start, const int end, const int addFlags)
{
    bool processing = true;
    while (processing && start < end)
    {
        MarkdownMarker &marker = markers[start];
        processing = false;
        if (marker.chr == '[' || marker.chr == ']' || marker.chr == '(' || marker.chr == ')')
        {
            if (marker.chr == '[')
            {
                MarkdownTag linkTag;
                MarkdownMarker extraMarker;
                for (int i = start + 1; i < end; i++)
                {
                    MarkdownMarker checkMarker = markers[i];
                    if ((checkMarker.chr == ']' && !linkTag.valid()) || (checkMarker.chr == ')' && linkTag.valid()))
                    {
                        if (!linkTag.valid())
                        {
                            linkTag.type = MARKDOWN_TAG_LINK;
                            linkTag.startPosition = marker.position;
                            linkTag.endPosition = checkMarker.position + checkMarker.weight;
                            linkTag.startText = linkTag.startPosition + marker.weight;
                            linkTag.endText = checkMarker.position;
                            linkTag.flags = addFlags;
                            addTags.push_back(linkTag);
                            start = i + 1;
                            if (start < end)
                            {
                                extraMarker = markers[start];
                                if (extraMarker.chr != '(' || extraMarker.position != checkMarker.position + checkMarker.weight)
                                {
                                    processing = true;
                                    break;
                                }
                            }
                        }
                        else if (extraMarker.valid())
                        {
                            linkTag.startExtra = extraMarker.position + extraMarker.weight;
                            linkTag.endExtra = checkMarker.position;
                            linkTag.endPosition = checkMarker.position + checkMarker.weight;
                            addTags[addTags.size() - 1] = linkTag;
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
                MarkdownMarker &checkMarker = markers[i];
                if (checkMarker.chr == marker.chr && checkMarker.weight >= marker.weight)
                {
                    MarkdownTag tag;
                    tag.type = checkMarker.chr == '~' ? MARKDOWN_TAG_ALTERNATIVE_TEXTSTYLE : MARKDOWN_TAG_TEXTSTYLE;
                    tag.weight = marker.weight;
                    tag.startPosition = marker.position;
                    tag.endPosition = checkMarker.position + marker.weight;
                    tag.startText = tag.startPosition + marker.weight;
                    tag.endText = checkMarker.position;
                    tag.flags = addFlags;
                    addTags.push_back(tag);
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
                processing = true;
            }
            else
            {
                start++;
            }
        }
    }
}


/**
 * Add the section tag and add additional tags within the section
 */
bool tagSortCallback(MarkdownTag &lhs, MarkdownTag &rhs)
{
    return (lhs.startPosition < rhs.startPosition);
}

void addStyleTags(std::vector<MarkdownTag> &foundTags, const UTFString &markdownText, const MarkdownTag &sectionTag)
{
    //First add the main section tag
    MarkdownTag mainTag;
    mainTag.type = sectionTag.type;
    mainTag.startPosition = sectionTag.startPosition;
    mainTag.endPosition = sectionTag.endPosition;
    mainTag.startText = sectionTag.startText;
    mainTag.endText = sectionTag.endText;
    mainTag.weight = sectionTag.weight;
    mainTag.flags = sectionTag.flags;
    foundTags.push_back(mainTag);

    //Traverse string and find tag markers
    std::vector<MarkdownMarker> tagMarkers;
    std::vector<MarkdownTag> addTags;
    UTFStringIndex maxLength = sectionTag.endText;
    int curMarkerWeight = 0;
    int curMarkerChar = 0;
    for (UTFStringIndex i = sectionTag.startText; i < maxLength; ++i)
    {
        int chr = markdownText[i];
        if (curMarkerChar != 0)
        {
            if (chr == curMarkerChar)
            {
                curMarkerWeight++;
            }
            else
            {
                tagMarkers.push_back(MarkdownMarker(curMarkerChar, curMarkerWeight, i - curMarkerWeight));
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
                tagMarkers.push_back(MarkdownMarker(chr, 1, i));
            }
        }
        if (chr == '\\')
        {
            ++i;
        }
    }
    if (curMarkerChar != 0)
    {
        tagMarkers.push_back(MarkdownMarker(curMarkerChar, curMarkerWeight, maxLength - curMarkerWeight));
    }

    //Sort tags to add and finally add them
    processMarkers(addTags, tagMarkers, 0, tagMarkers.size(), sectionTag.flags);
    std::sort(addTags.begin(), addTags.end(), tagSortCallback);
    for (int i = 0; i < addTags.size(); i++)
    {
        foundTags.push_back(addTags[i]);
    }
}


/**
 * Scan a single line of text within the markdown document, return section tag
 */
MarkdownTag scanLine(const UTFString &markdownText, UTFStringIndex position, UTFStringIndex maxLength, MARKDOWN_TAG_TYPE sectionType)
{
    if (position >= maxLength)
    {
        return MarkdownTag();
    }
    MarkdownTag styledTag;
    MarkdownTag normalTag;
    int skipChars = 0;
    int chr = 0, nextChr = markdownText[position], secondNextChr = 0;
    bool styleTagDefined = false, escaped = false;
    bool headerTokenSequence = false;
    if (position + 1 < maxLength)
    {
        secondNextChr = markdownText[position + 1];
    }
    normalTag.startPosition = position;
    styledTag.startPosition = position;
    for (UTFStringIndex i = position; i < maxLength; ++i)
    {
        chr = nextChr;
        nextChr = secondNextChr;
        if (i + 2 < maxLength)
        {
            secondNextChr = markdownText[i + 2];
        }
        if (skipChars > 0)
        {
            skipChars--;
            continue;
        }
        if (!escaped && chr == '\\')
        {
            normalTag.flags = normalTag.flags | MARKDOWN_FLAG_ESCAPED;
            styledTag.flags = styledTag.flags | MARKDOWN_FLAG_ESCAPED;
            escaped = true;
            continue;
        }
        if (escaped)
        {
            if (chr != '\n')
            {
                if (!normalTag.startText.valid())
                {
                    normalTag.startText = i;
                }
                if (!styledTag.startText.valid())
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
                if (!normalTag.startText.valid())
                {
                    normalTag.startText = i;
                }
                normalTag.endText = i + 1;
            }
            if (!styleTagDefined)
            {
                bool allowNewParagraph = sectionType == MARKDOWN_TAG_PARAGRAPH || sectionType == MARKDOWN_TAG_HEADER;
                bool continueBulletList = sectionType == MARKDOWN_TAG_UNORDERED_LIST || sectionType == MARKDOWN_TAG_ORDERED_LIST;
                if (chr == '#')
                {
                    styledTag.type = MARKDOWN_TAG_HEADER;
                    styledTag.weight = 1;
                    styleTagDefined = true;
                    headerTokenSequence = true;
                }
                else if ((allowNewParagraph || continueBulletList) && (chr == '*' || chr == '-' || chr == '+') && nextChr == ' ' && (i.chrPos - position.chrPos) % 2 == 0)
                {
                    styledTag.type = MARKDOWN_TAG_UNORDERED_LIST;
                    styledTag.weight = 1 + (i.chrPos - position.chrPos) / 2;
                    styleTagDefined = true;
                    skipChars = 1;
                }
                else if ((allowNewParagraph || continueBulletList) && chr >= '0' && chr <= '9' && nextChr == '.' && secondNextChr == ' ' && (i.chrPos - position.chrPos) % 2 == 0)
                {
                    styledTag.type = MARKDOWN_TAG_ORDERED_LIST;
                    styledTag.weight = 1 + (i.chrPos - position.chrPos) / 2;
                    styleTagDefined = true;
                    skipChars = 2;
                }
                else if (chr != ' ')
                {
                    styledTag.type = MARKDOWN_TAG_NORMAL;
                    styleTagDefined = true;
                }
            }
            else if (styledTag.type != MARKDOWN_TAG_NORMAL)
            {
                if (styledTag.type == MARKDOWN_TAG_HEADER)
                {
                    if (chr == '#' && headerTokenSequence)
                    {
                        styledTag.weight++;
                    }
                    else
                    {
                        headerTokenSequence = false;
                    }
                    if (chr != '#' && chr != ' ' && !styledTag.startText.valid())
                    {
                        styledTag.startText = i;
                        styledTag.endText = i + 1;
                    }
                    else if ((chr != '#' || (nextChr != '#' && nextChr != '\n' && nextChr != ' ' && nextChr != 0)) && chr != ' ' && styledTag.startText.valid())
                    {
                        styledTag.endText = i + 1;
                    }
                }
                else
                {
                    if (chr != ' ')
                    {
                        if (!styledTag.startText.valid())
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
    if (styleTagDefined && styledTag.type != MARKDOWN_TAG_NORMAL && styledTag.startText.valid() && styledTag.endText > styledTag.startText)
    {
        if (!styledTag.endPosition.valid())
        {
            styledTag.endPosition = maxLength;
        }
        return styledTag;
    }
    if (!normalTag.endPosition.valid())
    {
        normalTag.endPosition = maxLength;
    }
    normalTag.type = MARKDOWN_TAG_NORMAL;
    return normalTag;
}


/**
 * JNI function to find all supported markdown tags
 */
extern "C"
{
JNIEXPORT jintArray JNICALL
Java_com_crescentflare_simplemarkdownparser_core_SimpleMarkdownNativeParser_findNativeTags(JNIEnv *env, jobject instance, jstring markdownText_)
{
    //Java string conversion
    const char *markdownTextPointer = env->GetStringUTFChars(markdownText_, 0);
    UTFString markdownText(markdownTextPointer);

    //Loop over string and find tags
    std::vector<MarkdownTag> foundTags;
    const UTFStringIndex maxLength = markdownText.endIndex();
    UTFStringIndex paragraphStartPos(nullptr);
    MarkdownTag curLine = scanLine(markdownText, markdownText.startIndex(), maxLength, MARKDOWN_TAG_PARAGRAPH);
    while (curLine.valid())
    {
        //Fetch next line ahead
        bool hasNextLine = curLine.endPosition < maxLength;
        bool isEmptyLine = curLine.startPosition + 1 == curLine.endPosition;
        MARKDOWN_TAG_TYPE curType = curLine.type;
        if (isEmptyLine)
        {
            curType = MARKDOWN_TAG_PARAGRAPH;
        }
        MarkdownTag nextLine = hasNextLine ? scanLine(markdownText, curLine.endPosition, maxLength, curType) : MarkdownTag();

        //Insert section tag
        if (curLine.startText.valid())
        {
            addStyleTags(foundTags, markdownText, curLine);
        }
        else if (!isEmptyLine)
        {
            MarkdownTag spacedLineTag;
            spacedLineTag.type = curLine.type;
            spacedLineTag.startPosition = curLine.startPosition;
            spacedLineTag.endPosition = curLine.endPosition;
            spacedLineTag.startText = curLine.startPosition;
            spacedLineTag.endText = curLine.startPosition;
            spacedLineTag.weight = curLine.weight;
            spacedLineTag.flags = curLine.flags;
            foundTags.push_back(spacedLineTag);
        }

        //Insert paragraphs when needed
        if (nextLine.valid())
        {
            bool startNewParagraph = curLine.type == MARKDOWN_TAG_HEADER || nextLine.type == MARKDOWN_TAG_HEADER || nextLine.startPosition + 1 == nextLine.endPosition;
            bool stopParagraph = nextLine.startPosition + 1 != nextLine.endPosition;
            if (startNewParagraph && foundTags.size() > 0 && !paragraphStartPos.valid())
            {
                paragraphStartPos = curLine.endPosition;
            }
            if (stopParagraph && paragraphStartPos.valid())
            {
                MarkdownTag paragraphTag;
                paragraphTag.type = MARKDOWN_TAG_PARAGRAPH;
                paragraphTag.startPosition = paragraphStartPos;
                paragraphTag.endPosition = nextLine.startPosition;
                paragraphTag.startText = paragraphStartPos;
                paragraphTag.endText = paragraphStartPos;
                paragraphTag.weight = nextLine.type == MARKDOWN_TAG_HEADER ? 2 : 1;
                foundTags.push_back(paragraphTag);
                paragraphStartPos = UTFStringIndex(nullptr);
            }
        }

        //Set pointer to next line and continue
        curLine = nextLine;
    }

    //Convert tags into a java array, clean up and return
    jintArray returnArray = nullptr;
    jint *convertedValues = (jint *)malloc(foundTags.size() * tagFieldCount() * sizeof(jint));
    if (convertedValues)
    {
        returnArray = env->NewIntArray(foundTags.size() * tagFieldCount());
        int i;
        for (i = 0; i < foundTags.size(); i++)
        {
            fillTagToArray(&foundTags[i], &convertedValues[i * tagFieldCount()]);
        }
        env->SetIntArrayRegion(returnArray, 0, foundTags.size() * tagFieldCount(), convertedValues);
        free(convertedValues);
    }
    env->ReleaseStringUTFChars(markdownText_, markdownTextPointer);
    return returnArray;
}
}

/**
 * JNI function to extract an escaped string
 */
extern "C"
{
JNIEXPORT jstring JNICALL
Java_com_crescentflare_simplemarkdownparser_core_SimpleMarkdownNativeParser_escapedSubstring(JNIEnv *env, jobject instance, jstring text_, jint bytePosition, jint length)
{
    jstring returnValue = nullptr;
    const char *text = env->GetStringUTFChars(text_, 0);
    char *extractedText = (char *) malloc((size_t) length * 4);
    if (extractedText)
    {
        int srcPos = bytePosition;
        int destPos = 0;
        int i;
        size_t bytesTraversed = 0;
        for (i = 0; i < length; i++)
        {
            char chr = text[srcPos];
            int charSize = UTFStringIndex::charSize(chr);
            if (charSize != 1)
            {
                if (charSize == 0)
                {
                    charSize = 1;
                }
                chr = 0;
            }
            if (chr == '\\' && text[srcPos + 1] != '\n')
            {
                if (bytesTraversed > 0)
                {
                    memcpy(&extractedText[destPos], &text[srcPos - bytesTraversed], bytesTraversed);
                    destPos += bytesTraversed;
                    bytesTraversed = 0;
                }
            }
            else
            {
                bytesTraversed += charSize;
            }
            srcPos += charSize;
        }
        if (bytesTraversed > 0)
        {
            memcpy(&extractedText[destPos], &text[srcPos - bytesTraversed], bytesTraversed);
            destPos += bytesTraversed;
        }
        extractedText[destPos] = 0;
        returnValue = env->NewStringUTF(extractedText);
        free(extractedText);
    }
    env->ReleaseStringUTFChars(text_, text);
    return returnValue;
}
}