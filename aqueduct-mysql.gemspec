# Compiling the Gem
# gem build aqueduct-mysql.gemspec
# gem install ./aqueduct-mysql-x.x.x.gem
#
# gem push aqueduct-mysql-x.x.x.gem
# gem list -r aqueduct-mysql
# gem install aqueduct-mysql

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "aqueduct-mysql/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "aqueduct-mysql"
  s.version     = Aqueduct::Mysql::VERSION::STRING
  s.authors     = ["Remo Mueller"]
  s.email       = ["remosm@gmail.com"]
  s.homepage    = "https://github.com/remomueller"
  s.summary     = "Connect to MySQL through Aqueduct"
  s.description = "Connects to MySQL through Aqueduct interface"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["aqueduct-mysql.gemspec", "CHANGELOG.md", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails",     "~> 3.2.1"
  s.add_dependency "aqueduct",  "~> 0.1.0"
  s.add_dependency "mysql2",    "~> 0.3.11"

  s.add_development_dependency "sqlite3"
end
