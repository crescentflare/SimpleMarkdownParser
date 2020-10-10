//
//  SimpleMarkdownSymbolFinder.swift
//  SimpleMarkdownParser Pod
//
//  Library symbol parsing: defines the protocol of the symbol finder
//

// Symbol finder protocol
public protocol SimpleMarkdownSymbolFinder: class {
    
    var symbolStorage: SimpleMarkdownSymbolStorage { get }

    func scanText(_ text: String)

}
