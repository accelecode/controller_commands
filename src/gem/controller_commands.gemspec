
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "controller_commands/version"

Gem::Specification.new do |spec|
  spec.name          = "controller_commands"
  spec.version       = ControllerCommands::VERSION
  spec.authors       = ["Kevin Rood"]
  spec.email         = ["kevin.rood@accelecode.com"]

  spec.summary       = %q{A Rails controller concern which makes it easy to encapsulate validation and processing of complex incoming data into command classes.}
  spec.description   = %q{A Rails controller concern which makes it easy to encapsulate validation and processing of complex incoming data into command classes.}
  spec.homepage      = "https://github.com/accelecode/controller_commands"
  spec.license       = "Apache-2.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 12.3'

  spec.add_runtime_dependency 'dry-validation', '~> 0.11'
  spec.add_runtime_dependency 'hash_key_transformer', '~> 0.1'
  spec.add_runtime_dependency 'rails', '>= 4.2'
end
