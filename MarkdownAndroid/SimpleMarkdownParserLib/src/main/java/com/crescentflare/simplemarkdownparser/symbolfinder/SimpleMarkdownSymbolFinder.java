package com.crescentflare.simplemarkdownparser.symbolfinder;

import org.jetbrains.annotations.NotNull;

/**
 * Simple markdown parser library: symbol finder interface class
 * The interface to do the core (low-level) markdown parsing
 * It returns ranges for the markdown symbols which are used within the library
 * Use manually if the output needs to be highly customizable
 */
public interface SimpleMarkdownSymbolFinder
{
    @NotNull SimpleMarkdownSymbolStorage getSymbolStorage();
    void scanText(@NotNull String text);
}
