package com.crescentflare.simplemarkdownparser.tagfinder;

import com.crescentflare.simplemarkdownparser.symbolfinder.MarkdownSymbol;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Simple markdown parser library: tag finder class
 * Combine markdown symbols into tags
 */
public class SimpleMarkdownTagFinder {

    // --
    // High level parsing
    // --

    @NotNull public List<MarkdownTag> findTags(@NotNull String text, @NotNull List<MarkdownSymbol> symbols) {
        // Find first section tag
        ArrayList<MarkdownTag> result = new ArrayList<>();
        int sectionIndex = findNextSectionBlockIndex(symbols);
        int startSymbolIndex = 0;
        for (int index = 0; index < symbols.size(); index++) {
            if (symbols.get(index).startPosition >= symbols.get(sectionIndex).startPosition) {
                startSymbolIndex = index;
                break;
            }
        }

        // Add lines that could come before it
        if (startSymbolIndex > 0) {
            List<MarkdownSymbol> scanSymbols = symbols.subList(0, startSymbolIndex);
            MarkdownTag dummyParagraphTag = new MarkdownTag(
                MarkdownTag.Type.Paragraph, 0,
                symbols.get(0).startPosition,
                symbols.get(startSymbolIndex).startPosition - symbols.get(startSymbolIndex).linePosition
            );
            result.addAll(findLineTags(text, scanSymbols, dummyParagraphTag));
        }

        // Start finding inner tags
        while (sectionIndex >= 0) {
            // Set up section tag
            int nextSectionIndex = findNextSectionBlockIndex(symbols, sectionIndex);
            MarkdownTag sectionTag = makeSectionTag(text, symbols, sectionIndex, nextSectionIndex);
            result.add(sectionTag);

            // Determine symbols found within the section tag
            int endSymbolIndex = startSymbolIndex;
            for (int index = startSymbolIndex; index < symbols.size(); index++) {
                if (symbols.get(index).startPosition >= sectionTag.startPosition && symbols.get(index).endPosition <= sectionTag.endPosition) {
                    endSymbolIndex = index + 1;
                }
            }

            // Find line tags and shorten the section if empty lines are at the end
            List<MarkdownSymbol> scanSymbols = symbols.subList(startSymbolIndex, endSymbolIndex);
            List<MarkdownTag> lineTags = findLineTags(text, scanSymbols, sectionTag);
            result.addAll(lineTags);
            for (int index = 0; index < lineTags.size(); index++) {
                if (lineTags.get(index).startText >= lineTags.get(index).endText) {
                    if (index > 0) {
                        sectionTag.endPosition = lineTags.get(index - 1).endPosition;
                    }
                    break;
                }
            }

            // Add other tags within the section
            result.addAll(findTextStyleTags(scanSymbols));
            result.addAll(findLinkTags(text, scanSymbols));
            result.addAll(findListTags(text, scanSymbols, sectionTag));

            // Prepare for the next iteration
            startSymbolIndex = endSymbolIndex;
            sectionIndex = nextSectionIndex;
        }

        // Add escape symbols to tags
        ArrayList<MarkdownSymbol> escapeSymbols = new ArrayList<>();
        for (MarkdownSymbol symbol : symbols) {
            if (symbol.type == MarkdownSymbol.Type.Escape) {
                escapeSymbols.add(symbol);
            }
        }
        for (MarkdownTag tag : result) {
            for (MarkdownSymbol escapeSymbol : escapeSymbols) {
                if (escapeSymbol.startPosition >= tag.startPosition && escapeSymbol.startPosition < tag.endPosition) {
                    tag.escapeSymbols.add(escapeSymbol);
                }
            }
        }

        // Sort and return result
        Collections.sort(result);
        return result;
    }


    // --
    // Check sections
    // --

    private MarkdownTag makeSectionTag(String text, List<MarkdownSymbol> symbols, int fromIndex, int toIndex) {
        return makeSectionTag(text, symbols, fromIndex, toIndex, false);
    }

    private MarkdownTag makeSectionTag(String text, List<MarkdownSymbol> symbols, int fromIndex, int toIndex, boolean firstItem) {
        // Set position range
        int startPosition = firstItem ? 0 : symbols.get(fromIndex).startPosition - symbols.get(fromIndex).linePosition;
        int endPosition = toIndex >= 0 ? symbols.get(toIndex).startPosition - symbols.get(toIndex).linePosition : text.length();
        int startTextPosition = symbols.get(fromIndex).startPosition;
        int endTextPosition = symbols.get(fromIndex).endPosition;
        if (toIndex > fromIndex || toIndex < 0) {
            int endIndex = toIndex < 0 ? symbols.size() : toIndex;
            for (int index = fromIndex; index < endIndex; index++) {
                if (symbols.get(index).type == MarkdownSymbol.Type.TextBlock) {
                    endTextPosition = symbols.get(index).endPosition;
                }
            }
        }

        // Create tag
        MarkdownTag tag = new MarkdownTag(
            getSectionType(symbols, symbols.get(fromIndex)),
            0,
            startPosition,
            endPosition,
            startTextPosition,
            endTextPosition
        );

        // For headers, exclude header characters from text and determine weight, then trim for good measure
        if (tag.type == MarkdownTag.Type.Header) {
            boolean firstHeader = true;
            for (MarkdownSymbol symbol : symbols) {
                if (symbol.startPosition >= tag.startPosition) {
                    if (symbol.endPosition <= tag.endPosition) {
                        if (symbol.type == MarkdownSymbol.Type.Header) {
                            if (firstHeader) {
                                tag.startText = symbol.endPosition;
                                tag.weight = symbol.endPosition - symbol.startPosition;
                                firstHeader = false;
                            } else {
                                tag.endText = symbol.startPosition;
                                break;
                            }
                        }
                    } else {
                        break;
                    }
                }
            }
            trimTagSpaces(text, tag);
        }

        // Return result
        return tag;
    }

    private int findNextSectionBlockIndex(List<MarkdownSymbol> symbols) {
        return findNextSectionBlockIndex(symbols, -1);
    }

    private int findNextSectionBlockIndex(List<MarkdownSymbol> symbols, int afterSectionIndex) {
        MarkdownTag.Type afterSectionType = afterSectionIndex >= 0 ? getSectionType(symbols, symbols.get(afterSectionIndex)) : MarkdownTag.Type.Paragraph;
        int consecutiveNewlines = 0;
        int previousListLinePosition = afterSectionIndex >= 0 ? symbols.get(afterSectionIndex).linePosition : 0;
        for (int index = afterSectionIndex + 1; index < symbols.size(); index++) {
            if (symbols.get(index).type == MarkdownSymbol.Type.Newline) {
                consecutiveNewlines += 1;
            } else if (symbols.get(index).type == MarkdownSymbol.Type.TextBlock) {
                MarkdownTag.Type sectionType = getSectionType(symbols, symbols.get(index));
                boolean canAbortEarly = sectionType == MarkdownTag.Type.Header || afterSectionType == MarkdownTag.Type.Header || sectionType != afterSectionType;
                if (afterSectionType == MarkdownTag.Type.List && sectionType == MarkdownTag.Type.Paragraph && symbols.get(index).linePosition >= previousListLinePosition) {
                    canAbortEarly = false;
                }
                if (consecutiveNewlines > 1 || afterSectionIndex < 0 || (consecutiveNewlines > 0 && canAbortEarly)) {
                    return index;
                } else {
                    consecutiveNewlines = 0;
                }
            } else if (symbols.get(index).type == MarkdownSymbol.Type.OrderedListItem || symbols.get(index).type == MarkdownSymbol.Type.UnorderedListItem) {
                previousListLinePosition = symbols.get(index).linePosition + symbols.get(index).endPosition - symbols.get(index).startPosition + 1;
            }
        }
        return -1;
    }

    private MarkdownTag.Type getSectionType(List<MarkdownSymbol> symbols, MarkdownSymbol nearSymbol) {
        int checkLine = nearSymbol.line;
        int checkLinePosition = nearSymbol.linePosition;
        for (MarkdownSymbol symbol : symbols) {
            if (symbol.line == checkLine && symbol.linePosition == checkLinePosition) {
                switch (symbol.type) {
                    case Header:
                    return MarkdownTag.Type.Header;
                    case OrderedListItem:
                    case UnorderedListItem:
                        return MarkdownTag.Type.List;
                    default:
                        break;
                }
            } else if (symbol.line > checkLine) {
                break;
            }
        }
        return MarkdownTag.Type.Paragraph;
    }


    // --
    // Check lines
    // --

    private List<MarkdownTag> findLineTags(String text, List<MarkdownSymbol> symbols, MarkdownTag section) {
        // Search for newline symbols
        ArrayList<MarkdownTag> result = new ArrayList<>();
        MarkdownSymbol sectionSymbol = new MarkdownSymbol(MarkdownSymbol.Type.TextBlock, 0, section.startPosition, section.endPosition, 0);
        MarkdownSymbol startSymbol = sectionSymbol;
        for (MarkdownSymbol symbol : symbols) {
            if (symbol.type == MarkdownSymbol.Type.Newline) {
                result.add(makeLineTag(text, startSymbol, symbol));
                startSymbol = symbol;
            }
        }

        // Handle remains
        if (startSymbol.endPosition < sectionSymbol.endPosition || startSymbol == sectionSymbol) {
            result.add(makeLineTag(text, startSymbol, sectionSymbol));
        }

        // Return result
        return result;
    }

    private MarkdownTag makeLineTag(String text, MarkdownSymbol startSymbol, MarkdownSymbol endSymbol) {
        MarkdownTag tag = new MarkdownTag(
            MarkdownTag.Type.Line, 0,
            startSymbol.type == MarkdownSymbol.Type.Newline ? startSymbol.endPosition : startSymbol.startPosition,
            endSymbol.endPosition,
            startSymbol.type == MarkdownSymbol.Type.Newline ? startSymbol.endPosition : startSymbol.startPosition,
            endSymbol.type == MarkdownSymbol.Type.Newline ? endSymbol.startPosition : endSymbol.endPosition
        );
        trimTagSpaces(text, tag);
        return tag;
    }


    // --
    // Check text styles
    // --

    private List<MarkdownTag> findTextStyleTags(List<MarkdownSymbol> symbols) {
        // Find matching text style symbols in two batches (the second one is used to catch edge cases)
        ArrayList<MarkdownTag> result = new ArrayList<>();
        ArrayList<MarkdownSymbol> checkSymbols = new ArrayList<>();
        for (MarkdownSymbol symbol : symbols) {
            if (symbol.type.isTextStyle()) {
                checkSymbols.add(symbol);
            }
        }
        int phase = 0;
        while (phase < 2 && checkSymbols.size() > 1) {
            for (int index = 0; index < checkSymbols.size() - 1; index++) {
                if (phase == 0 && checkSymbols.get(index + 1).type == checkSymbols.get(index).type) {
                    result.add(makeTextStyleTag(checkSymbols.get(index), checkSymbols.get(index + 1)));
                    checkSymbols.remove(checkSymbols.get(index + 1));
                    checkSymbols.remove(checkSymbols.get(index));
                    break;
                } else if (phase == 1) {
                    int nextIndex = -1;
                    for (int i = index + 1; i < checkSymbols.size(); i++) {
                        if (checkSymbols.get(i).type == checkSymbols.get(index).type) {
                            nextIndex = i;
                            break;
                        }
                    }
                    if (nextIndex > 0) {
                        result.add(makeTextStyleTag(checkSymbols.get(index), checkSymbols.get(nextIndex)));
                        for (int i = nextIndex; i >= index; i--) {
                            checkSymbols.remove(checkSymbols.get(i));
                        }
                        break;
                    }
                }
                if (index == checkSymbols.size() - 2) {
                    phase += 1;
                    break;
                }
            }
        }

        // Return result
        return result;
    }

    private MarkdownTag makeTextStyleTag(MarkdownSymbol startSymbol, MarkdownSymbol endSymbol) {
        int weight = Math.min(startSymbol.endPosition - startSymbol.startPosition, endSymbol.endPosition - endSymbol.startPosition);
        return new MarkdownTag(
            startSymbol.type == MarkdownSymbol.Type.ThirdTextStyle ? MarkdownTag.Type.AlternativeTextStyle : MarkdownTag.Type.TextStyle, weight,
            startSymbol.startPosition,
            endSymbol.endPosition,
            startSymbol.startPosition + weight,
            endSymbol.endPosition - weight
        );
    }


    // --
    // Check links
    // --

    private List<MarkdownTag> findLinkTags(String text, List<MarkdownSymbol> symbols) {
        // Find enclosing link symbols and compose tags (with optional URL override)
        ArrayList<MarkdownTag> result = new ArrayList<>();
        MarkdownSymbol inLinkSymbol = null;
        for (MarkdownSymbol symbol : symbols) {
            if (symbol.type == MarkdownSymbol.Type.Newline) {
                inLinkSymbol = null;
            } else if (symbol.type == MarkdownSymbol.Type.OpenLink && inLinkSymbol == null) {
                inLinkSymbol = symbol;
            } else if (inLinkSymbol != null && symbol.type == MarkdownSymbol.Type.CloseLink) {
                result.add(makeLinkTag(text, inLinkSymbol, symbol, symbols));
                inLinkSymbol = null;
            }
        }

        // Return result
        return result;
    }

    private MarkdownTag makeLinkTag(String text, MarkdownSymbol startSymbol, MarkdownSymbol endSymbol, List<MarkdownSymbol> symbols) {
        // Set up basic tag
        MarkdownTag tag = new MarkdownTag(
            MarkdownTag.Type.Link, 0,
            startSymbol.startPosition,
            endSymbol.endPosition,
            startSymbol.startPosition + 1,
            endSymbol.endPosition - 1
        );

        // Add extra information if found
        MarkdownSymbol inUrlSymbol = null;
        int foundDoubleQuotes = 0;
        int cutOffExtraPosition = 0;
        for (MarkdownSymbol symbol : symbols) {
            if (symbol.startPosition == endSymbol.endPosition && symbol.type == MarkdownSymbol.Type.OpenUrl) {
                inUrlSymbol = symbol;
            } else if (symbol.startPosition > endSymbol.endPosition && (inUrlSymbol == null || symbol.type == MarkdownSymbol.Type.Newline)) {
                break;
            } else if (inUrlSymbol != null && symbol.type == MarkdownSymbol.Type.DoubleQuote) {
                if (foundDoubleQuotes == 0) {
                    cutOffExtraPosition = symbol.startPosition;
                }
                foundDoubleQuotes += 1;
            } else if (inUrlSymbol != null && symbol.type == MarkdownSymbol.Type.CloseUrl) {
                tag.startExtra = inUrlSymbol.endPosition;
                tag.endExtra = foundDoubleQuotes > 1 ? cutOffExtraPosition : symbol.startPosition;
                tag.endPosition = symbol.endPosition;
                trimExtraSpaces(text, tag);
                break;
            }
        }

        // Return result
        return tag;
    }


    // --
    // Check lists
    // --

    private List<MarkdownTag> findListTags(String text, List<MarkdownSymbol> symbols, MarkdownTag section) {
        // Find ordered and unordered list items and compose tags
        ArrayList<MarkdownTag> result = new ArrayList<>();
        MarkdownSymbol inListSymbol = null;
        for (MarkdownSymbol symbol : symbols) {
            if (symbol.type == MarkdownSymbol.Type.OrderedListItem || symbol.type == MarkdownSymbol.Type.UnorderedListItem) {
                if (inListSymbol != null) {
                    result.add(makeListItemTag(text, inListSymbol, symbol.startPosition));
                }
                inListSymbol = symbol;
            }
        }

        // Add last list item (if needed) and return result
        if (inListSymbol != null) {
            result.add(makeListItemTag(text, inListSymbol, section.endPosition));
        }
        return result;
    }

    private MarkdownTag makeListItemTag(String text, MarkdownSymbol startSymbol, int endPosition) {
        MarkdownTag tag = new MarkdownTag(
            startSymbol.type == MarkdownSymbol.Type.OrderedListItem ? MarkdownTag.Type.OrderedList : MarkdownTag.Type.UnorderedList,
            1 + startSymbol.linePosition / 2,
            startSymbol.startPosition,
            endPosition,
            startSymbol.endPosition,
            endPosition
        );
        trimTagSpaces(text, tag);
        return tag;
    }


    // --
    // Helpers
    // --

    private void trimTagSpaces(String text, MarkdownTag tag) {
        // Update start
        int startTextPosition = tag.startText;
        while (startTextPosition < tag.endText && isWhitespace(text.charAt(startTextPosition))) {
            startTextPosition += 1;
        }
        tag.startText = startTextPosition;

        // Update end
        int endTextPosition = tag.endText;
        while (endTextPosition > tag.startText) {
            if (!isWhitespace(text.charAt(endTextPosition - 1))) {
                break;
            }
            endTextPosition -= 1;
        }
        tag.endText = endTextPosition;
    }

    private void trimExtraSpaces(String text, MarkdownTag tag) {
        int endExtraPosition = tag.endExtra;
        if (endExtraPosition >= 0) {
            while (endExtraPosition > tag.startExtra) {
                if (!isWhitespace(text.charAt(endExtraPosition - 1))) {
                    break;
                }
                endExtraPosition -= 1;
            }
            tag.endExtra = endExtraPosition;
        }
    }

    private boolean isWhitespace(char chr) {
        return chr == ' ' || chr == '\t' || chr == '\n';
    }
}
