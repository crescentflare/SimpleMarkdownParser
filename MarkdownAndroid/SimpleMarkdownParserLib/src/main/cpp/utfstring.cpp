#include <malloc.h>
#include "utfstring.h"

/**
 * UTFString implementation: public
 */

UTFString::UTFString(const char *utfCharArray)
{
    this->utfCharArray = utfCharArray;
}

UTFStringIndex UTFString::startIndex()
{
    return UTFStringIndex(this);
}

UTFStringIndex UTFString::endIndex()
{
    if (!cachedEndIndex)
    {
        cachedEndIndex = new UTFStringIndex(this);
        cachedEndIndex->increase(9999999);
    }
    return *cachedEndIndex;
}


/**
 * UTFString implementation: public (operators)
 */

int UTFString::operator[](const UTFStringIndex &index) const
{
    unsigned char chrSize = UTFStringIndex::charSize(utfCharArray[index.bytePos]);
    if (chrSize == 1)
    {
        return utfCharArray[index.bytePos];
    }
    return 0; //Don't care about any other characters for analyzing tags
}


/**
 * UTFStringIndex implementation: public
 */

UTFStringIndex::UTFStringIndex(UTFString *str)
{
    if (str)
    {
        utfCharArray = str->utfCharArray;
    }
    else
    {
        utfCharArray = nullptr;
        bytePos = -1;
        chrPos = -1;
    }
}

UTFStringIndex::UTFStringIndex(const UTFStringIndex &other)
{
    utfCharArray = other.utfCharArray;
    bytePos = other.bytePos;
    chrPos = other.chrPos;
}

UTFStringIndex &UTFStringIndex::increase(int count)
{
    if (utfCharArray)
    {
        while (count > 0)
        {
            if (utfCharArray[bytePos] == 0)
            {
                break;
            }
            unsigned char chrSize = charSize(utfCharArray[bytePos]);
            if (chrSize > 0)
            {
                bytePos += chrSize;
                chrPos++;
            }
            else
            {
                break;
            }
            count--;
        }
    }
    return *this;
}

UTFStringIndex &UTFStringIndex::decrease(int count)
{
    if (utfCharArray)
    {
        while (count > 0)
        {
            if (bytePos == 0)
            {
                break;
            }
            unsigned char chrSize;
            if (bytePos > 3 && charSize(utfCharArray[bytePos - 4]) == 4)
            {
                chrSize = 4;
            }
            else if (bytePos > 2 && charSize(utfCharArray[bytePos - 3]) == 3)
            {
                chrSize = 3;
            }
            else if (bytePos > 1 && charSize(utfCharArray[bytePos - 2]) == 2)
            {
                chrSize = 2;
            }
            else if (bytePos > 0 && charSize(utfCharArray[bytePos - 1]) == 1)
            {
                chrSize = 1;
            }
            else
            {
                break;
            }
            bytePos -= chrSize;
            chrPos--;
            count--;
        }
    }
    return *this;
}

bool UTFStringIndex::valid()
{
    return utfCharArray && bytePos >= 0 && chrPos >= 0;
}


/**
 * UTFStringIndex implementation: public (operators)
 */

bool UTFStringIndex::operator==(const UTFStringIndex &compare)
{
    return utfCharArray == compare.utfCharArray && chrPos == compare.chrPos && bytePos == compare.bytePos;
}

bool UTFStringIndex::operator!=(const UTFStringIndex &compare)
{
    return !(utfCharArray == compare.utfCharArray && chrPos == compare.chrPos && bytePos == compare.bytePos);
}

bool UTFStringIndex::operator<=(const UTFStringIndex &compare)
{
    return utfCharArray == compare.utfCharArray && chrPos <= compare.chrPos;
}

bool UTFStringIndex::operator>=(const UTFStringIndex &compare)
{
    return utfCharArray == compare.utfCharArray && chrPos >= compare.chrPos;
}

bool UTFStringIndex::operator<(const UTFStringIndex &compare)
{
    return utfCharArray == compare.utfCharArray && chrPos < compare.chrPos;
}

bool UTFStringIndex::operator>(const UTFStringIndex &compare)
{
    return utfCharArray == compare.utfCharArray && chrPos > compare.chrPos;
}

UTFStringIndex &UTFStringIndex::operator++()
{
    increase(1);
    return *this;
}

UTFStringIndex &UTFStringIndex::operator--()
{
    decrease(1);
    return *this;
}

UTFStringIndex &UTFStringIndex::operator+=(int count)
{
    increase(count);
    return *this;
}

UTFStringIndex &UTFStringIndex::operator-=(int count)
{
    decrease(count);
    return *this;
}

UTFStringIndex UTFStringIndex::operator+(int count) const
{
    UTFStringIndex result = *this;
    result.increase(count);
    return result;
}

UTFStringIndex UTFStringIndex::operator-(int count) const
{
    UTFStringIndex result = *this;
    result.decrease(count);
    return result;
}
