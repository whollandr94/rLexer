require_relative 'tokenizer.rb'
require_relative 'named_characters.rb'


file_contents = File.open("www/index.html").read
html_tokenize = Tokenizer.new(file_contents)

html_tokenize.run
pp html_tokenize.all_tokens
