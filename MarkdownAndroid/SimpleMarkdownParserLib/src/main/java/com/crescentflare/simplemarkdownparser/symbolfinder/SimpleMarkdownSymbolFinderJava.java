package com.crescentflare.simplemarkdownparser.symbolfinder;

import org.jetbrains.annotations.NotNull;

/**
 * Simple markdown parser library: symbol finder java class
 * Implements the symbol finder in java
 */
public class SimpleMarkdownSymbolFinderJava implements SimpleMarkdownSymbolFinder {

    // --
    // Members
    // --

    private final SimpleMarkdownSymbolStorage symbolStorage = new SimpleMarkdownSymbolStorage();
    private int currentLine = 0;
    private int linePosition = 0;
    private int lastEscapePosition = -100;
    private MarkdownSymbol currentTextBlockSymbol;
    private MarkdownSymbol currentHeaderSymbol;
    private MarkdownSymbol currentTextStyleSymbol;
    private MarkdownSymbol currentListItemSymbol;
    private boolean needListDotSeparator = false;


    // --
    // Scanning text
    // --

    @NotNull public SimpleMarkdownSymbolStorage getSymbolStorage() {
        return symbolStorage;
    }

    public void scanText(@NotNull String text) {
        // Prepare
        symbolStorage.clearSymbols();

        // Scan text
        for (int i = 0; i < text.length(); i++) {
            addCharacter(i, text.charAt(i));
        }

        // Finalize
        finalizeScanning();
    }


    // --
    // Internal symbol finder
    // --

    private void addCharacter(int position, Character character) {
        // Handle character escaping
        boolean escaped;
        if (character == '\\') {
            if (lastEscapePosition != position - 1) {
                lastEscapePosition = position;
                symbolStorage.addSymbol(new MarkdownSymbol(MarkdownSymbol.Type.Escape, currentLine, position, position + 1, linePosition));
            }
            escaped = true;
        } else {
            escaped = lastEscapePosition == position - 1;
        }

        // Check for double quotes
        if (!escaped && character == '\"') {
            symbolStorage.addSymbol(new MarkdownSymbol(MarkdownSymbol.Type.DoubleQuote, currentLine, position, position + 1, linePosition));
        }

        // Check for text blocks
        boolean isTextCharacter = escaped || (character != ' ' && character != '\n' && character != '\t');
        if (currentTextBlockSymbol != null) {
            if (isTextCharacter) {
                currentTextBlockSymbol.updateEndPosition(position + 1);
            }
        } else if (isTextCharacter) {
            currentTextBlockSymbol = new MarkdownSymbol(MarkdownSymbol.Type.TextBlock, currentLine, position, position + 1, linePosition);
        }

        // Check for newlines
        if (character == '\n' && !escaped) {
            if (currentTextBlockSymbol != null) {
                symbolStorage.addSymbol(currentTextBlockSymbol);
                currentTextBlockSymbol = null;
            }
            symbolStorage.addSymbol(new MarkdownSymbol(MarkdownSymbol.Type.Newline, currentLine, position, position + 1, linePosition));
        }

        // Check for headers
        boolean isHeaderCharacter = character == '#' && !escaped;
        if (currentHeaderSymbol != null) {
            if (isHeaderCharacter) {
                currentHeaderSymbol.updateEndPosition(position + 1);
            } else {
                symbolStorage.addSymbol(currentHeaderSymbol);
                currentHeaderSymbol = null;
            }
        } else if (isHeaderCharacter) {
            currentHeaderSymbol = new MarkdownSymbol(MarkdownSymbol.Type.Header, currentLine, position, position + 1, linePosition);
        }

        // Check for text styles
        MarkdownSymbol.Type textStyleType = MarkdownSymbol.Type.Escape;
        if (!escaped) {
            if (character == '*') {
                textStyleType = MarkdownSymbol.Type.FirstTextStyle;
            } else if (character == '_') {
                textStyleType = MarkdownSymbol.Type.SecondTextStyle;
            } else if (character == '~') {
                textStyleType = MarkdownSymbol.Type.ThirdTextStyle;
            }
        }
        if (currentTextStyleSymbol != null) {
            if (currentTextStyleSymbol.type == textStyleType) {
                currentTextStyleSymbol.updateEndPosition(position + 1);
            } else {
                symbolStorage.addSymbol(currentTextStyleSymbol);
                currentTextStyleSymbol = null;
                if (textStyleType != MarkdownSymbol.Type.Escape) {
                    currentTextStyleSymbol = new MarkdownSymbol(textStyleType, currentLine, position, position + 1, linePosition);
                }
            }
        } else if (textStyleType != MarkdownSymbol.Type.Escape) {
            currentTextStyleSymbol = new MarkdownSymbol(textStyleType, currentLine, position, position + 1, linePosition);
        }

        // Check for lists
        if (!escaped) {
            if (currentListItemSymbol != null) {
                if (currentListItemSymbol.type == MarkdownSymbol.Type.UnorderedListItem && character == ' ') {
                    symbolStorage.addSymbol(currentListItemSymbol);
                    currentListItemSymbol = null;
                } else if (currentListItemSymbol.type == MarkdownSymbol.Type.OrderedListItem) {
                    if (needListDotSeparator && ((character >= '0' && character <= '9') || character == '.')) {
                        currentListItemSymbol.updateEndPosition(position + 1);
                        if (character == '.') {
                            needListDotSeparator = false;
                        }
                    } else if (!needListDotSeparator && character == ' ') {
                        symbolStorage.addSymbol(currentListItemSymbol);
                        currentListItemSymbol = null;
                    } else {
                        currentListItemSymbol = null;
                    }
                } else {
                    currentListItemSymbol = null;
                }
            } else if (currentTextBlockSymbol != null && currentTextBlockSymbol.startPosition == position) {
                boolean isBulletCharacter = character == '*' || character == '+' || character == '-';
                if (isBulletCharacter || (character >= '0' && character <= '9')) {
                    currentListItemSymbol = new MarkdownSymbol(isBulletCharacter ? MarkdownSymbol.Type.UnorderedListItem : MarkdownSymbol.Type.OrderedListItem, currentLine, position, position + 1, linePosition);
                    needListDotSeparator = !isBulletCharacter;
                }
            }
        } else {
            currentListItemSymbol = null;
        }

        // Check for links
        if (!escaped) {
            MarkdownSymbol.Type linkSymbolType;
            if (character == '[') {
                linkSymbolType = MarkdownSymbol.Type.OpenLink;
            } else if (character == ']') {
                linkSymbolType = MarkdownSymbol.Type.CloseLink;
            } else if (character == '(') {
                linkSymbolType = MarkdownSymbol.Type.OpenUrl;
            } else if (character == ')') {
                linkSymbolType = MarkdownSymbol.Type.CloseUrl;
            } else {
                linkSymbolType = MarkdownSymbol.Type.Escape;
            }
            if (linkSymbolType != MarkdownSymbol.Type.Escape) {
                symbolStorage.addSymbol(new MarkdownSymbol(linkSymbolType, currentLine, position, position + 1, linePosition));
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

    private void finalizeScanning() {
        // Finish symbol finders in progress
        if (currentTextBlockSymbol != null) {
            symbolStorage.addSymbol(currentTextBlockSymbol);
        }
        if (currentHeaderSymbol != null) {
            symbolStorage.addSymbol(currentHeaderSymbol);
        }
        if (currentTextStyleSymbol != null) {
            symbolStorage.addSymbol(currentTextStyleSymbol);
        }

        // Sort found symbols and remove duplicates
        symbolStorage.sort();
        symbolStorage.cleanOverlaps();
    }
}
