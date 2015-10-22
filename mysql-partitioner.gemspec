# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mysql/partitioner/version'

Gem::Specification.new do |spec|
  spec.name          = "mysql-partitioner"
  spec.version       = Mysql::Partitioner::VERSION
  spec.authors       = ["maedama"]
  spec.email         = ["maedama85@gmail.com"]

  spec.summary       = %q{mysql partition management tools}
  spec.description   = %q{mysql partition management ttools}
  spec.homepage      = "https://github.com/maedama/mysql-partitioner"
  spec.license       = "MIT"
 
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "mysql2"
  spec.add_dependency "deep_hash_transform"
  
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "rspec-instafail"
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
