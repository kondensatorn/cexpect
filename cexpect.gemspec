# frozen_string_literal: true

require_relative 'lib/cexpect/version'

Gem::Specification.new do |spec|
  spec.name          = 'cexpect'
  spec.version       = Cexpect::VERSION
  spec.authors       = ['Christer Jansson']
  spec.email         = ['christer@janssons.org']

  spec.summary       = 'An improved expect method'
  spec.description   = 'An expect method with more reasonable return' \
                       ' values and logging functionality'
  spec.homepage      = 'https://github.com/kondensatorn/cexpect'
  spec.license       = 'BSD 2-clause'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have
  # been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.
      split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
