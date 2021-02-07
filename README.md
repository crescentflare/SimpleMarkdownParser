# SimpleMarkdownParser

[![CI Status](http://img.shields.io/travis/crescentflare/SimpleMarkdownParser.svg?style=flat)](https://travis-ci.org/crescentflare/SimpleMarkdownParser)
[![License](https://img.shields.io/cocoapods/l/SimpleMarkdownParser.svg?style=flat)](http://cocoapods.org/pods/SimpleMarkdownParser)
[![Version](https://img.shields.io/cocoapods/v/SimpleMarkdownParser.svg?style=flat)](http://cocoapods.org/pods/SimpleMarkdownParser)
[![Version](https://img.shields.io/maven-central/v/com.crescentflare.simplemarkdownparser/SimpleMarkdownParserLib.svg?style=flat)](https://repo1.maven.org/maven2/com/crescentflare/simplemarkdownparser/SimpleMarkdownParserLib)

A multi-functional and easy way to integrate markdown formatting within mobile apps. Supports iOS and Android.

⚠️ **Notice for Android developers**: JCenter plans to shut down in may 2021. To mitigate this, the SimpleMarkdownParser library has moved to Maven Central from version 0.7.1 onwards. Make sure to update to the latest version in time.

**Important**  
In version 0.7.0 the parser has been mostly rewritten using modern parsing techniques to make it more easy to add new features later. There is a migration guide available on the [wiki](https://github.com/crescentflare/SimpleMarkdownParser/wiki) which lists all the improvements and changes on how to make your app compatible with the new version. If you find a bug that was not in the previous version, make sure to create an [issue](https://github.com/crescentflare/SimpleMarkdownParser/issues) (including a sample of the markdown text causing the bug).


### Features

* Easy to use, convert markdown to attributed text for UILabels (iOS) or spannable strings for TextViews (Android)
* Highly customizable, use markdown parse phases directly to search for markdown symbols and tags for customized styling and text processing
* Also customizable without using the core library through a simple protocol (iOS) or interface (Android)
* Parses the following markdown tags: headers (\#), text styles (italics and bold), strike through text, lists and links
* Supports escaping of markdown tag characters (using \\)
* Uses fast native code (optionally) for Android to do the core parsing work


### iOS integration guide

##### CocoaPods
The library is available through [CocoaPods](http://cocoapods.org). To install it, simply add one of the following lines to your Podfile.

```ruby
pod "SimpleMarkdownParser", '~> 0.7.1'
```

##### Carthage

```ruby
github "crescentflare/SimpleMarkdownParser" ~> 0.7.1
```

##### Older versions

The newest version is for Swift 5.0. For older Swift versions use the following:
- Swift 4.2: SimpleMarkdownParser 0.6.2
- Swift 4.1: SimpleMarkdownParser 0.5.6
- Swift 4.0: SimpleMarkdownParser 0.5.5
- Swift 3: SimpleMarkdownParser 0.5.4
- Swift 2.2: SimpleMarkdownParser 0.5.0


### Android integration guide

When using gradle, the library can easily be imported into the build.gradle file of your project. Add the following dependency:

```
compile 'com.crescentflare.simplemarkdownparser:SimpleMarkdownParserLib:0.7.1'
```

Make sure that jcenter is added as a repository.

The above library has a minimum deployment target of Android API level 14. It should also work better with the latest gradle and NDK plugins. Below is an old version which supports Android API level 9 and may rely on an old gradle or NDK plugin.

```
compile ('com.crescentflare.simplemarkdownparser:SimpleMarkdownParserLib:0.5.0') {
transitive = false
}
```

### Example

The provided example shows how to parse markdown, convert it to an attributed text or spannable string (or html) and show it on a text view. Also it contains an example on how to apply custom styling easily.


### Status

The library has just been rewritten to use more modern parsing techniques. It has been tested using unit tests and several samples, but there are still risks for bugs (read the disclaimer at the top). It should be feature complete for the most common markdown cases. More markdown support and features may be added later.
