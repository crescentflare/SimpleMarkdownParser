# SimpleMarkdownParser

[![CI Status](http://img.shields.io/travis/crescentflare/SimpleMarkdownParser.svg?style=flat)](https://travis-ci.org/crescentflare/SimpleMarkdownParser)
[![License](https://img.shields.io/cocoapods/l/SimpleMarkdownParser.svg?style=flat)](http://cocoapods.org/pods/SimpleMarkdownParser)
[![Version](https://img.shields.io/cocoapods/v/SimpleMarkdownParser.svg?style=flat)](http://cocoapods.org/pods/SimpleMarkdownParser)
[![Version](https://img.shields.io/bintray/v/crescentflare/maven/SimpleMarkdownParserLib.svg?style=flat)](https://bintray.com/crescentflare/maven/SimpleMarkdownParserLib)

A multi-functional and easy way to integrate markdown formatting within mobile apps. Supports iOS and Android.


### Features

* Easy to use, convert markdown to attributed text for UILabels (iOS) or spannable strings for TextViews (Android)
* Highly customizable, use the core library to search for markdown tags for customized styling
* Also customizable without using the core library through a simple protocol (iOS) or interface (Android)
* Parses the following markdown tags: headers (\#), text styles (italics and bold), strike through text, lists and links
* Supports escaping of markdown tag characters (using \\)
* Uses fast native code (optionally) for Android to do the core parsing work


### iOS integration guide

The library is available through [CocoaPods](http://cocoapods.org). To install it, simply add one of the following lines to your Podfile.

Swift 4:

```ruby
pod "SimpleMarkdownParser", '~> 0.5.5'
```

Swift 3:

```ruby
pod "SimpleMarkdownParser", '~> 0.5.4'
```

Swift 2.2:

```ruby
pod "SimpleMarkdownParser", '0.5.0'
```


### Android integration guide

When using gradle, the library can easily be imported into the build.gradle file of your project. Add the following dependency:

```
compile ('com.crescentflare.simplemarkdownparser:SimpleMarkdownParserLib:0.5.0') {
transitive = false
}
```

Make sure that jcenter is added as a repository.


### Example

The provided example shows how to parse markdown, convert it to an attributed text or spannable string (or html) and show it on a text view. Also it contains an example on how to apply custom styling easily.


### Status

The library is new and doesn't contain all markdown features, but the commonly used features should be supported. Markdown conversion and customization is now complete enough to be used in an easy way. More markdown support and features will be added later.
