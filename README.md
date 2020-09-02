# rLexer | HTML Lexer

A simple HTML lexer/tokenizer written in Ruby.

## Using rLexer

The values returned from rLexer is a n-dimensional array which contains the token type and the data. See example below

```ruby
require 'rLexer'

html = '<html><head><title></title></head></html>'

t = Tokenizer.new(html)
t.tokenize

pp t.tokens
```

This generates the following n-dimensional array:

<pre>
[[:OPEN, "html"],
 [:OPEN, "head"],
 [:OPEN, "title"],
 [:DATA, "Hello, World!"],
 [:CLOSE, "title"],
 [:CLOSE, "head"],
 [:CLOSE, "html"]]
</pre>

### Comments

Comments are handled as shown below:

```ruby
require rLexer

html = '<html><head><title><!--Hello, World!</title></head></html>'

t = Tokenizer.new(html)
t.tokenize

pp t.tokens
```

This will results in:

<pre>
[[:OPEN, "html"],
 [:OPEN, "head"],
 [:OPEN, "title"],
 [:COMMENT, "Hello, World!</title></head></html>"]]
</pre>

Closed comments work as follows:

```ruby
require rLexer

html = '<html><head><title><!--Hello, World!--></title></head></html>'

t = Tokenizer.new(html)
t.tokenize

pp t.tokens
```

Which will result in:

<pre>
[[:OPEN, "html"],
 [:OPEN, "head"],
 [:OPEN, "title"],
 [:COMMENT, "Hello, World!"],
 [:CLOSE, "title"],
 [:CLOSE, "head"],
 [:CLOSE, "html"]]
</pre>

### Attributes

Attributes are stored in the n-dimensional array directly after the tag that contains them in an array of its own.

```ruby
require rLexer

html = '<html xmlns="http://www.w3.org/1999/xhtml" lang="en"><head><title>Hello, World!</title></head></html>'

t = Tokenizer.new(html)
t.tokenize

pp t.tokens
```

This creates the following:

<pre>
[[:OPEN, "html"],
 [:ATTRIBUTES, ["xmlns='http://www.w3.org/1999/xhtml", "lang='en'"]],
 [:OPEN, "head"],
 [:OPEN, "title"],
 [:DATA, "Hello, World!"],
 [:CLOSE, "title"],
 [:CLOSE, "head"],
 [:CLOSE, "html"]]
</pre>

## Limitations
  * HTML Doctype not supported
  * Style and Script tag act as regular tags - Any text inside will be treated as data
  * Self closing tags not supported
  * Comments can't occur in the middle of a tag: 
    * <tit &lt;!-- --&gt;le> will result in [:OPEN, "<tit &lt;!-- --&gt;le>"]
  * Boolean attributes not supported (readonly, disabled)
  
## Coming Soon
 * Doctype support
 * Self closing tags
 * Fix comment placement
 * Boolean attributes
 * HTML parsing
