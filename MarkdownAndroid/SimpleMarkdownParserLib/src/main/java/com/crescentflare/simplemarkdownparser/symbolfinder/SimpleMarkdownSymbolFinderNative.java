package com.crescentflare.simplemarkdownparser.symbolfinder;

import org.jetbrains.annotations.NotNull;

/**
 * Simple markdown parser library: symbol finder native interface class
 * Implements the symbol finder through native code
 */
public class SimpleMarkdownSymbolFinderNative implements SimpleMarkdownSymbolFinder {

    // --
    // Import native library
    // --

    static {
        System.loadLibrary("simplemarkdownparser_native");
    }


    // --
    // Members
    // --

    private final SimpleMarkdownSymbolStorage symbolStorage = new SimpleMarkdownSymbolStorage();


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
        int[] nativeSymbols = scanNativeText(text);
        int count = getSymbolCount(nativeSymbols);
        for (int i = 0; i < count; i++) {
            MarkdownSymbol symbol = getConvertedSymbol(nativeSymbols, i);
            if (symbol != null) {
                symbolStorage.addSymbol(symbol);
            }
        }

        // Finalize
        symbolStorage.sort();
        symbolStorage.cleanOverlaps();
    }

    private native int[] scanNativeText(String markdownText);


    // --
    // Native conversion
    // --

    private static final int FIELD_COUNT = 5;

    private int getSymbolCount(final int[] nativeSymbols) {
        if (nativeSymbols == null) {
            return 0;
        }
        return nativeSymbols.length / FIELD_COUNT;
    }

    private MarkdownSymbol getConvertedSymbol(final int[] nativeSymbols, int position) {
        position *= FIELD_COUNT;
        MarkdownSymbol.Type type = getConvertedSymbolType(nativeSymbols[position]);
        if (type != null) {
            return new MarkdownSymbol(
                    type,
                    nativeSymbols[position + 1],
                    nativeSymbols[position + 2],
                    nativeSymbols[position + 3],
                    nativeSymbols[position + 4]
            );
        }
        return null;
    }

    private MarkdownSymbol.Type getConvertedSymbolType(int nativeEnumValue) {
        switch (nativeEnumValue) {
            case 1:
                return MarkdownSymbol.Type.Escape;
            case 2:
                return MarkdownSymbol.Type.DoubleQuote;
            case 3:
                return MarkdownSymbol.Type.TextBlock;
            case 4:
                return MarkdownSymbol.Type.Newline;
            case 5:
                return MarkdownSymbol.Type.Header;
            case 6:
                return MarkdownSymbol.Type.FirstTextStyle;
            case 7:
                return MarkdownSymbol.Type.SecondTextStyle;
            case 8:
                return MarkdownSymbol.Type.ThirdTextStyle;
            case 9:
                return MarkdownSymbol.Type.OrderedListItem;
            case 10:
                return MarkdownSymbol.Type.UnorderedListItem;
            case 11:
                return MarkdownSymbol.Type.OpenLink;
            case 12:
                return MarkdownSymbol.Type.CloseLink;
            case 13:
                return MarkdownSymbol.Type.OpenUrl;
            case 14:
                return MarkdownSymbol.Type.CloseUrl;
        }
        return null;
    }
}
