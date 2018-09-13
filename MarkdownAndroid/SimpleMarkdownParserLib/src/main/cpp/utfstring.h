/**
 * Forward class declaration
 */

class UTFStringIndex;
class UTFString;


/**
 * A utility class to handle UTF(8) strings more easily than a character array
 */

class UTFString
{
    friend class UTFStringIndex;

private:
    UTFStringIndex *cachedEndIndex = nullptr;
    const char *utfCharArray;

public:
    UTFString(const char *utfCharArray);
    UTFStringIndex startIndex();
    UTFStringIndex endIndex();

public:
    const int operator[](const UTFStringIndex index) const;
};


/**
 * Used to index UTF(8) strings
 */

class UTFStringIndex
{
    friend class UTFString;

public:
    int bytePos = 0;
    int chrPos = 0;

private:
    const char *utfCharArray;

public:
    UTFStringIndex(UTFString *str);
    UTFStringIndex(const UTFStringIndex &other);
    UTFStringIndex &increase(int count);
    UTFStringIndex &decrease(int count);
    bool valid();

public:
    bool operator==(const UTFStringIndex &compare);
    bool operator!=(const UTFStringIndex &compare);
    bool operator<=(const UTFStringIndex &compare);
    bool operator>=(const UTFStringIndex &compare);
    bool operator<(const UTFStringIndex &compare);
    bool operator>(const UTFStringIndex &compare);
    UTFStringIndex &operator++();
    UTFStringIndex &operator--();
    UTFStringIndex &operator+=(int count);
    UTFStringIndex &operator-=(int count);
    UTFStringIndex operator+(int count) const;
    UTFStringIndex operator-(int count) const;

public:
    static const unsigned char charSize(const char chr)
    {
        return (unsigned char)((chr & 0x80) == 0x0 ? 1 : ((chr & 0xE0) == 0xC0 ? 2 : ((chr & 0xF0) == 0xE0 ? 3 : ((chr & 0xF8) == 0xF0 ? 4 : 0))));
    }
};
