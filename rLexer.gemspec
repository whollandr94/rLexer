
Gem::Specification.new do |spec|
  spec.name          = "rLexer"
  spec.version       = '0.1.13'
  spec.authors       = ["Robert Holland"]
  spec.email         = ["rlexerdevelopment@gmail.com"]

  spec.summary       = %q{A simple HTML lexer/tokenizer written in Ruby.}
  spec.homepage      = "https://github.com/whollandr94/rLexer"
  spec.license       = "MIT"

  spec.files         = spec.files = Dir.glob('lib/**/*')
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
