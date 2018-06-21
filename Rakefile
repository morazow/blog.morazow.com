# frozen_string_literal: true

require 'jekyll'
require 'shellwords'
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

  desc 'Run all linter tasks'
  task all: %i[ruby yaml markdown]

  desc 'Lint ruby files syntax'
  RuboCop::RakeTask.new(:ruby).tap do |task|
    task.options = %w[--fail-fast --extra-details]
  end

  desc 'Lint yaml files syntax'
  task yaml: %i[] do
    files = Dir.glob('*.y*ml', File::FNM_DOTMATCH)
    run_command "yaml-lint #{files.join(' ')}" unless files.empty?
  end

  desc 'Lint markdown files syntax'
  task markdown: %i[] do
    md_files = Dir.glob('**/*.md')
    md_files.reject! { |dir| dir.start_with? 'vendor/' }
    puts "Looking at #{md_files.join ', '}"
    md_files.each do |directory|
      escaped = Shellwords.escape(directory)
      run_command "mdl #{escaped}"
    end
  end
end

# rubocop:disable BlockLength
namespace 'proofer' do
  def run_html_proofer!(opts)
    HTMLProofer.check_directory('./_site', opts).run
  end

  desc 'Run all html proofer tasks'
  task all: %i[local remote]

  desc 'Run html proofer for local'
  task local: %i[build] do
    opts = {
      check_img_http: true,
      disable_external: true,
      assume_extension: true
    }
    run_html_proofer!(opts)
  end

  desc 'Run html proofer for remote'
  task remote: %i[build] do
    opts = {
      external_only: true,
      assume_extension: true,
      http_status_ignore: [999],
      cache: { timeframe: '1w' },
      hydra: { max_concurrency: 10 },
      internal_domains: ['www.morazow.com']
    }
    run_html_proofer!(opts)
  end
end
# rubocop:enable BlockLength
