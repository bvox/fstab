# encoding: utf-8

require 'rubygems'
require 'bundler'
require './lib/fstab.rb'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.version = Fstab::VERSION
  gem.name = "fstab"
  gem.homepage = "http://github.com/bvox/fstab"
  gem.license = "MIT"
  gem.summary = %Q{Linux fstab helper library}
  gem.description = %Q{Linux fstab helper library}
  gem.email = "rubiojr@bvox.net"
  gem.authors = ["Sergio Rubio"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "fstab #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
