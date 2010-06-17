require 'rubygems'
require 'rake'
require 'rspec'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "github"
    gem.summary = %Q{The official `github` command line helper.}
    gem.description = %Q{Simplifies your GitHub experience.}
    gem.email = "kmandrup@gmail.com"
    gem.homepage = "http://github.com/kristianmandrup/github"
    gem.authors = ['Chris Wanstrath', 'Kevin Ballard', 'Scott Chacon', 'Dr Nic Williams', 'Kristian Mandrup']
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_dependency "text-format", ">=1.0.0"
    gem.add_dependency "highline", "~>1.5.1"
    gem.add_dependency "json", ">=1.2.0" 
    gem.add_dependency "faster-xml-simple", ">=0.6.4"    
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

# Uncomment if you are using rspec < 2
# Spec::Rake::SpecTask.new(:spec) do |spec|
#   spec.libs << 'lib' << 'spec'
#   spec.spec_files = FileList['spec/**/*_spec.rb']
# end
# 
# Spec::Rake::SpecTask.new(:rcov) do |spec|
#   spec.libs << 'lib' << 'spec'
#   spec.pattern = 'spec/**/*_spec.rb'
#   spec.rcov = true
# end
# 
# task :spec => :check_dependencies
# 
# task :default => :spec
# 
# require 'rake/rdoctask'
# Rake::RDocTask.new do |rdoc|
#   version = File.exist?('VERSION') ? File.read('VERSION') : ""
# 
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title = "github #{version}"
#   rdoc.rdoc_files.include('README*')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end
