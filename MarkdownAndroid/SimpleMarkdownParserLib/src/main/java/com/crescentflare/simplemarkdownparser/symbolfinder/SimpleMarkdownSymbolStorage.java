package com.crescentflare.simplemarkdownparser.symbolfinder;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Simple markdown parser library: symbol storage
 * Stores markdown symbols being found during text scanning
 */
public class SimpleMarkdownSymbolStorage
{
    // --
    // Members
    // --

    @NotNull public List<MarkdownSymbol> symbols = new ArrayList<>();


    // --
    // Storage
    // --

    public void addSymbol(@NotNull MarkdownSymbol symbol) {
        symbols.add(symbol);
    }

    public void clearSymbols() {
        symbols = new ArrayList<>();
    }

    public void sort() {
        Collections.sort(symbols);
    }


    // --
    // Cleaning
    // --

    public void cleanOverlaps() {
        // Collect indices to remove
        List<Integer> removeSymbols = new ArrayList<>();

        // Unordered list items override text style
        for (int index = 0; index < symbols.size(); index++) {
            if (symbols.get(index).type == MarkdownSymbol.Type.FirstTextStyle && symbols.get(index).endPosition - symbols.get(index).startPosition == 1) {
                int startIndex = index + 1;
                for (int checkIndex = index - 1; checkIndex >= 0; checkIndex--) {
                    if (symbols.get(checkIndex).startPosition == symbols.get(index).startPosition) {
                        startIndex = checkIndex;
                    } else {
                        break;
                    }
                }
                for (int checkIndex = startIndex; checkIndex < symbols.size(); checkIndex++) {
                    if (checkIndex != index) {
                        if (symbols.get(checkIndex).startPosition == symbols.get(index).startPosition) {
                            if (symbols.get(checkIndex).type == MarkdownSymbol.Type.UnorderedListItem){
                                removeSymbols.add(index);
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                }
            }
        }

        // Remove symbols
        for (int i = removeSymbols.size() - 1; i >= 0 ; i--) {
            int removeIndex = removeSymbols.get(i);
            symbols.remove(removeIndex);
        }
    }
}
