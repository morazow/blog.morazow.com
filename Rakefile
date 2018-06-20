# frozen_string_literal: true

require 'jekyll'
require 'html-proofer'
require 'rubocop/rake_task'

namespace 'jekyll' do
  desc 'Build the jekyll website, e.g bundle exec jekyll build'
  task :build do
    Jekyll::Commands::Build.process(profile: true)
  end

  desc 'Removes jekyll build results, e.g _site, .jekyll-metadata, .sass-cache'
  task :clean do
    Jekyll::Commands::Clean.process({})
  end
end

desc 'Build the jekyll website if it has not been built yet'
task build: ['_site/index.html']

file '_site/index.html' do
  Rake::Task['jekyll:build'].execute
end

namespace 'linter' do
  def run_command(cmd)
    puts "Running '#{cmd}'"
    sh cmd
  end

  desc 'Run all tasks in this namespace'
  task all: %i[ruby yaml]

  desc 'Lint ruby files syntax'
  RuboCop::RakeTask.new(:ruby).tap do |task|
    task.options = %w[--fail-fast --extra-details]
  end

  desc 'Lint yaml files syntax'
  task yaml: %i[] do
    files = Dir.glob('*.y*ml', File::FNM_DOTMATCH)
    run_command "yaml-lint #{files.join(' ')}" unless files.empty?
  end
end
