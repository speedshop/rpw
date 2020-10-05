require_relative "lib/rpw"

Gem::Specification.new do |spec|
  spec.name = "rpw"
  spec.version = RPW::VERSION
  spec.authors = ["Nate Berkopec"]
  spec.email = ["nate@speedshop.co"]

  spec.summary = "A CLI for the Rails Performance Workshop."
  spec.homepage = "https://speedshop.co"
  spec.license = "GPL-3.0-or-later"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://www.github.com/speedshop/rpw"
  spec.metadata["changelog_uri"] = "https://www.github.com/speedshop/rpw/HISTORY.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "typhoeus"
end
