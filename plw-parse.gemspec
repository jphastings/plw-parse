spec = Gem::Specification.new do |s| 
  s.name = "PLW Parse"
  s.version = "0.1"
  s.author = "JP Hastings-Spital"
  s.email = "contact@projects.kedakai.co.uk"
  s.homepage = "http://wiki.github.com/jphastings/plw-parse"
  s.platform = Gem::Platform::RUBY
  s.summary = "Parses PicoTech's PLW files and allows access to the data therein. Also parses the PLS file used to create the data."
  s.files = ["plw.rb"]
  s.require_path = "."
  s.has_rdoc = true
end