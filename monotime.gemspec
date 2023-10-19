
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "monotime/version"

Gem::Specification.new do |spec|
  spec.name          = "monotime"
  spec.version       = Monotime::MONOTIME_VERSION
  spec.authors       = ["Thomas Hurst"]
  spec.email         = ["tom@hur.st"]

  spec.summary       = %q{A sensible interface to the monotonic clock}
  spec.homepage      = "https://github.com/Freaky/monotime"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 2.7.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "simplecov", "~> 0.21"

  if RUBY_PLATFORM != 'java' && RUBY_VERSION.split(".").first.to_i >= 3
    spec.add_development_dependency "steep", "~> 1.5"
    spec.add_development_dependency "rbs", "~> 3.2"
  end
end
