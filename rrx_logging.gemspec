# frozen_string_literal: true

require_relative 'lib/rrx_logging/version'

Gem::Specification.new do |spec|
  source_uri = 'https://github.com/rails-rrx/rrx_logging'
  home_uri = source_uri

  spec.name = 'rrx_logging'
  spec.version = RrxLogging::VERSION
  spec.authors = ['Dan Drew']
  spec.email = ['dan.drew@hotmail.com']

  spec.summary = 'Ruby on Rails API core logging support'
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = home_uri
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata['homepage_uri'] = home_uri
  spec.metadata['source_code_uri'] = source_uri
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'railties'
  spec.add_dependency 'rrx_config'
  spec.add_development_dependency 'rrx_dev'
  spec.add_development_dependency 'sqlite3'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
