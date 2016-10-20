# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruboty/cloudfront/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruboty-cloudfront'
  spec.version       = Ruboty::Cloudfront::VERSION
  spec.authors       = ['Sho Kusano']
  spec.email         = ['sho-kusano@zeny.io']

  spec.summary       = 'Provides cloud front operation to ruboty'
  spec.description   = 'Provides cloud front operation to ruboty'
  spec.homepage      = 'https://github.com/zeny-io/ruboty-cloudfront'

  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_dependency 'ruboty'
  spec.add_dependency 'aws-sdk', '~> 2.0'
end
