// --
// Includes
// --

#include <jni.h>
#include <cstdlib>
#include <algorithm>
#include <vector>
#include <cstring>
#include "utfstring.h"


// --
// Constants, enum, struct and utility functions for markdown symbols
// --

typedef enum {
    MARKDOWN_SYMBOL_INVALID = 0,
    MARKDOWN_SYMBOL_ESCAPE,
    MARKDOWN_SYMBOL_DOUBLE_QUOTE,
    MARKDOWN_SYMBOL_TEXT_BLOCK,
    MARKDOWN_SYMBOL_NEWLINE,
    MARKDOWN_SYMBOL_HEADER,
    MARKDOWN_SYMBOL_FIRST_TEXT_STYLE,
    MARKDOWN_SYMBOL_SECOND_TEXT_STYLE,
    MARKDOWN_SYMBOL_THIRD_TEXT_STYLE,
    MARKDOWN_SYMBOL_ORDERED_LIST_ITEM,
    MARKDOWN_SYMBOL_UNORDERED_LIST_ITEM,
    MARKDOWN_SYMBOL_OPEN_LINK,
    MARKDOWN_SYMBOL_CLOSE_LINK,
    MARKDOWN_SYMBOL_OPEN_URL,
    MARKDOWN_SYMBOL_CLOSE_URL
}MARKDOWN_SYMBOL_TYPE;

class MarkdownSymbol {
public:
    MARKDOWN_SYMBOL_TYPE type;
    UTFStringIndex startIndex;
    UTFStringIndex endIndex;
    int line;
    int linePosition;
public:
    MarkdownSymbol(): type(MARKDOWN_SYMBOL_INVALID), startIndex(UTFStringIndex(nullptr)), endIndex(UTFStringIndex(nullptr)), line(0), linePosition(0) {
    }

    MarkdownSymbol(MARKDOWN_SYMBOL_TYPE type, int line, const UTFStringIndex &startIndex, const UTFStringIndex &endIndex, int linePosition): type(type), startIndex(startIndex), endIndex(endIndex), line(line), linePosition(linePosition) {
    }

    MarkdownSymbol(const MarkdownSymbol &other): type(other.type), startIndex(other.startIndex), endIndex(other.endIndex), line(other.line), linePosition(other.linePosition) {
    }

    void update(MARKDOWN_SYMBOL_TYPE newType, int newLine, const UTFStringIndex &newStartIndex, const UTFStringIndex &newEndIndex, int newLinePosition) {
        type = newType;
        startIndex = newStartIndex;
        endIndex = newEndIndex;
        line = newLine;
        linePosition = newLinePosition;
    }

    bool valid() const {
        return type != MARKDOWN_SYMBOL_INVALID;
    }

    void makeInvalid() {
        type = MARKDOWN_SYMBOL_INVALID;
    }

    void updateEndPosition(const UTFStringIndex &index) {
        endIndex = index;
    }

    void toArray(jint *ptr) const {
        if (ptr) {
            ptr[0] = type;
            ptr[1] = line;
            ptr[2] = startIndex.chrPos;
            ptr[3] = endIndex.chrPos;
            ptr[4] = linePosition;
        }
    }

    static unsigned char fieldCount() {
        return 5;
    }
};


// --
// Markdown symbol finder class
// --

class MarkdownNativeSymbolFinder {
public:
    std::vector<MarkdownSymbol> symbols;
private:
    int currentLine = 0;
    int linePosition = 0;
    int lastEscapePosition = -100;
    MarkdownSymbol currentTextBlockSymbol;
    MarkdownSymbol currentHeaderSymbol;
    MarkdownSymbol currentTextStyleSymbol;
    MarkdownSymbol currentListItemSymbol;
    bool needListDotSeparator = false;
public:
    void addCharacter(int position, const UTFStringIndex &index, const UTFStringIndex &nextIndex, int character) {
        // Handle character escaping
        bool escaped;
        if (character == '\\') {
            if (lastEscapePosition != position - 1) {
                lastEscapePosition = position;
                symbols.emplace_back(MARKDOWN_SYMBOL_ESCAPE, currentLine, index, nextIndex, linePosition);
            }
            escaped = true;
        } else {
            escaped = lastEscapePosition == position - 1;
        }

        // Check for double quotes
        if (!escaped && character == '\"') {
            symbols.emplace_back(MARKDOWN_SYMBOL_DOUBLE_QUOTE, currentLine, index, nextIndex, linePosition);
        }

        // Check for text blocks
        bool isTextCharacter = escaped || (character != ' ' && character != '\n' && character != '\t');
        if (currentTextBlockSymbol.valid()) {
            if (isTextCharacter) {
                currentTextBlockSymbol.updateEndPosition(nextIndex);
            }
        } else if (isTextCharacter) {
            currentTextBlockSymbol.update(MARKDOWN_SYMBOL_TEXT_BLOCK, currentLine, index, nextIndex, linePosition);
        }

        // Check for newlines
        if (character == '\n' && !escaped) {
            if (currentTextBlockSymbol.valid()) {
                symbols.emplace_back(MarkdownSymbol(currentTextBlockSymbol));
                currentTextBlockSymbol.makeInvalid();
            }
            symbols.emplace_back(MARKDOWN_SYMBOL_NEWLINE, currentLine, index, nextIndex, linePosition);
        }

        // Check for headers
        bool isHeaderCharacter = character == '#' && !escaped;
        if (currentHeaderSymbol.valid()) {
            if (isHeaderCharacter) {
                currentHeaderSymbol.updateEndPosition(nextIndex);
            } else {
                symbols.emplace_back(MarkdownSymbol(currentHeaderSymbol));
                currentHeaderSymbol.makeInvalid();
            }
        } else if (isHeaderCharacter) {
            currentHeaderSymbol.update(MARKDOWN_SYMBOL_HEADER, currentLine, index, nextIndex, linePosition);
        }

        // Check for text styles
        MARKDOWN_SYMBOL_TYPE textStyleType = MARKDOWN_SYMBOL_ESCAPE;
        if (!escaped) {
            if (character == '*') {
                textStyleType = MARKDOWN_SYMBOL_FIRST_TEXT_STYLE;
            } else if (character == '_') {
                textStyleType = MARKDOWN_SYMBOL_SECOND_TEXT_STYLE;
            } else if (character == '~') {
                textStyleType = MARKDOWN_SYMBOL_THIRD_TEXT_STYLE;
            }
        }
        if (currentTextStyleSymbol.valid()) {
            if (currentTextStyleSymbol.type == textStyleType) {
                currentTextStyleSymbol.updateEndPosition(nextIndex);
            } else {
                symbols.emplace_back(MarkdownSymbol(currentTextStyleSymbol));
                currentTextStyleSymbol.makeInvalid();
                if (textStyleType != MARKDOWN_SYMBOL_ESCAPE) {
                    currentTextStyleSymbol.update(textStyleType, currentLine, index, nextIndex, linePosition);
                }
            }
        } else if (textStyleType != MARKDOWN_SYMBOL_ESCAPE) {
            currentTextStyleSymbol.update(textStyleType, currentLine, index, nextIndex, linePosition);
        }

        // Check for lists
        if (!escaped) {
            if (currentListItemSymbol.valid()) {
                if (currentListItemSymbol.type == MARKDOWN_SYMBOL_UNORDERED_LIST_ITEM && character == ' ') {
                    symbols.emplace_back(MarkdownSymbol(currentListItemSymbol));
                    currentListItemSymbol.makeInvalid();
                } else if (currentListItemSymbol.type == MARKDOWN_SYMBOL_ORDERED_LIST_ITEM) {
                    if (needListDotSeparator && ((character >= '0' && character <= '9') || character == '.')) {
                        currentListItemSymbol.updateEndPosition(nextIndex);
                        if (character == '.') {
                            needListDotSeparator = false;
                        }
                    } else if (character == ' ') {
                        symbols.emplace_back(MarkdownSymbol(currentListItemSymbol));
                        currentListItemSymbol.makeInvalid();
                    } else {
                        currentListItemSymbol.makeInvalid();
                    }
                } else {
                    currentListItemSymbol.makeInvalid();
                }
            } else if (currentTextBlockSymbol.valid() && currentTextBlockSymbol.startIndex.chrPos == position) {
                bool isBulletCharacter = character == '*' || character == '+' || character == '-';
                if (isBulletCharacter || (character >= '0' && character <= '9')) {
                    currentListItemSymbol.update(isBulletCharacter ? MARKDOWN_SYMBOL_UNORDERED_LIST_ITEM : MARKDOWN_SYMBOL_ORDERED_LIST_ITEM, currentLine, index, nextIndex, linePosition);
                    needListDotSeparator = !isBulletCharacter;
                }
            }
        } else {
            currentListItemSymbol.makeInvalid();
        }

        // Check for links
        if (!escaped) {
            MARKDOWN_SYMBOL_TYPE linkSymbolType;
            if (character == '[') {
                linkSymbolType = MARKDOWN_SYMBOL_OPEN_LINK;
            } else if (character == ']') {
                linkSymbolType = MARKDOWN_SYMBOL_CLOSE_LINK;
            } else if (character == '(') {
                linkSymbolType = MARKDOWN_SYMBOL_OPEN_URL;
            } else if (character == ')') {
                linkSymbolType = MARKDOWN_SYMBOL_CLOSE_URL;
            } else {
                linkSymbolType = MARKDOWN_SYMBOL_ESCAPE;
            }
            if (linkSymbolType != MARKDOWN_SYMBOL_ESCAPE) {
                symbols.emplace_back(linkSymbolType, currentLine, index, nextIndex, linePosition);
            }
        }

        // Update line position
        if (!escaped && character == '\n') {
            linePosition = 0;
            currentLine += 1;
        } else if (lastEscapePosition != position) {
            linePosition += 1;
        }
    }

    void finalizeScanning() {
        if (currentTextBlockSymbol.valid()) {
            symbols.emplace_back(currentTextBlockSymbol);
        }
        if (currentHeaderSymbol.valid()) {
            symbols.emplace_back(currentHeaderSymbol);
        }
        if (currentTextStyleSymbol.valid()) {
            symbols.emplace_back(currentTextStyleSymbol);
        }
    }
};


// --
// JNI function to find all supported markdown symbols
// --

extern "C"
{
JNIEXPORT jintArray JNICALL
Java_com_crescentflare_simplemarkdownparser_symbolfinder_SimpleMarkdownSymbolFinderNative_scanNativeText(JNIEnv *env, jobject instance, jstring markdownText_) {
    // Java string conversion
    const char *markdownTextPointer = env->GetStringUTFChars(markdownText_, nullptr);
    UTFString markdownText(markdownTextPointer);

    // Loop over string and find symbols
    MarkdownNativeSymbolFinder symbolFinder;
    const UTFStringIndex maxLength = markdownText.endIndex();
    UTFStringIndex index = markdownText.startIndex();
    while (index < maxLength) {
        const UTFStringIndex nextIndex = index + 1;
        symbolFinder.addCharacter(index.chrPos, index, nextIndex, markdownText[index]);
        index = nextIndex;
    }
    symbolFinder.finalizeScanning();

    // Convert symbols into a java array, clean up and return
    jintArray returnArray = nullptr;
    jint *convertedValues = (jint *)malloc(symbolFinder.symbols.size() * MarkdownSymbol::fieldCount() * sizeof(jint));
    if (convertedValues) {
        returnArray = env->NewIntArray(symbolFinder.symbols.size() * MarkdownSymbol::fieldCount());
        int i;
        for (i = 0; i < symbolFinder.symbols.size(); i++) {
            symbolFinder.symbols[i].toArray(&convertedValues[i * MarkdownSymbol::fieldCount()]);
        }
        env->SetIntArrayRegion(returnArray, 0, symbolFinder.symbols.size() * MarkdownSymbol::fieldCount(), convertedValues);
        free(convertedValues);
    }
    env->ReleaseStringUTFChars(markdownText_, markdownTextPointer);
    return returnArray;
}
}
