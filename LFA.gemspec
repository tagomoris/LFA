# frozen_string_literal: true

require_relative "lib/LFA/version"

Gem::Specification.new do |spec|
  spec.name = "LFA"
  spec.version = LFA::VERSION
  spec.authors = ["Satoshi Tagomori"]
  spec.email = ["tagomoris@gmail.com"]

  spec.summary = "Lambda Function Adapter for web applications"
  spec.description = "Web application framework to mount AWS Lambda functions as request handlers"
  spec.homepage = "https://github.com/tagomoris/LFA"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "rack"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "rake"
end
