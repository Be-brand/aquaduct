# frozen_string_literal: true

require_relative "lib/aquaduct/version"

Gem::Specification.new do |spec|
  spec.name = "aquaduct"
  spec.version = Aquaduct::VERSION
  spec.authors = ["Eden Landau"]
  spec.email = ["edenworky@gmail.com"]

  spec.summary = "Serial channeler with smart cancelling and reporting"
  spec.required_ruby_version = ">= 3.1.2"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
