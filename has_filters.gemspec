
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "has_filters/version"

Gem::Specification.new do |spec|
  spec.name          = "has_filters"
  spec.version       = HasFilters::VERSION
  spec.authors       = ["T Floyd Wright"]
  spec.email         = ["floyd@politech.io"]

  spec.summary       = %q{Configurable filter scopes for SQL-backed ActiveRecord models}
  spec.description   = %q{Configurable filter scopes for SQL-backed ActiveRecord models}
  spec.homepage      = "https://github.com/politechdev/has_filters"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/politechdev/has_filters"
    spec.metadata["changelog_uri"] = "https://github.com/politechdev/has_filters/blob/master/README.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir.glob("lib/**/*.*") + %w(LICENSE README.md)
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 5.2"
  spec.add_dependency "activesupport", "~> 5.0"
  spec.add_dependency "pg", "~> 1"


  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-collection_matchers", "~> 1.1.3"
  spec.add_development_dependency "database_cleaner-active_record", "~> 1.5"
end
