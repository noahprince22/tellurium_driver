# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'tellurium_driver'
  s.version     = '1.2.4'
  s.date        = '2014-06-07'
  s.summary     = "Extends the functionality of Selenium WebDriver"
  s.description = "Provides useful extra methods for Selenium WebDriver, especially helpful in javascript webapps"
  s.authors     = ["Noah Prince", "Jordan Prince"]
  s.email       = 'noahprince8@gmail.com'
  s.files       = `git ls-files`.split($/)
  s.homepage    =
    'http://www.github.com/noahprince22/tellurium_driver'
  s.license       = 'MIT'

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
end
