# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{github}
  s.version = "0.4.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chris Wanstrath", "Kevin Ballard", "Scott Chacon", "Dr Nic Williams", "Kristian Mandrup"]
  s.date = %q{2010-06-17}
  s.description = %q{Simplifies your GitHub experience.}
  s.email = %q{kmandrup@gmail.com}
  s.executables = ["gh", "github"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.md"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "Rakefile",
     "VERSION",
     "lib/github.rb",
     "spec/github_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/kristianmandrup/github}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{The official `github` command line helper.}
  s.test_files = [
    "spec/command_spec.rb",
     "spec/commands/command_browse_spec.rb",
     "spec/commands/command_clone_spec.rb",
     "spec/commands/command_config_spec.rb",
     "spec/commands/command_create-from-local_spec.rb",
     "spec/commands/command_fetch_spec.rb",
     "spec/commands/command_fork_spec.rb",
     "spec/commands/command_helper.rb",
     "spec/commands/command_home_spec.rb",
     "spec/commands/command_info_spec.rb",
     "spec/commands/command_issues_spec.rb",
     "spec/commands/command_network_spec.rb",
     "spec/commands/command_pull-request_spec.rb",
     "spec/commands/command_pull_spec.rb",
     "spec/commands/command_search_spec.rb",
     "spec/commands/command_track_spec.rb",
     "spec/commands_spec.rb",
     "spec/extensions_spec.rb",
     "spec/github_spec.rb",
     "spec/helper_spec.rb",
     "spec/spec_helper.rb",
     "spec/windoze_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_runtime_dependency(%q<text-format>, [">= 1.0.0"])
      s.add_runtime_dependency(%q<highline>, ["~> 1.5.1"])
      s.add_runtime_dependency(%q<json>, [">= 1.2.0"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_dependency(%q<text-format>, [">= 1.0.0"])
      s.add_dependency(%q<highline>, ["~> 1.5.1"])
      s.add_dependency(%q<json>, [">= 1.2.0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
    s.add_dependency(%q<text-format>, [">= 1.0.0"])
    s.add_dependency(%q<highline>, ["~> 1.5.1"])
    s.add_dependency(%q<json>, [">= 1.2.0"])
  end
end

