require File.dirname(__FILE__) + "/loadpath_bootstrap"

# =============================================================================
# custom tasks for running selenium
# =============================================================================

namespace :selenium do
  desc "Run the selenium tests in Firefox"
  Rake::TestTask.new(:test_with_server_started) do |t| 
    t.pattern = ENV['test'] || "test/selenium/selenium_suite.rb"
  end

  desc "Run the selenium remote-control server"
  task :server do
    require "selenium"
    Selenium::SeleniumServer.run(['-interactive'])
  end

  desc "Run the selenium servant in the foreground"
  task :run_server do
    require "selenium"
    Selenium::SeleniumServer.run([])
  end

  desc "Start the selenium servant (the server that launches browsers) on localhost"
  task :start_servant do
    require "funkytown/selenium_task"
    Funkytown::SeleniumTask.new.start_servant
  end

  desc "Stop the selenium servant (the server that launches browsers) on localhost"
  task :stop_servant do
    require "funkytown/selenium_task"
    Funkytown::SeleniumTask.new.stop_servant
  end

  desc "Stop and start the selenium servant (the server that launches browsers) on localhost"
  task :restart_servant => [:stop_servant, :start_servant]

  desc "Run a selenium test file (default test/selenium/selenium_suite)"
  task :test do
    ENV['RAILS_ENV'] ||= 'test'
    require "funkytown/selenium_task"
    Funkytown::SeleniumTask.new.run_test(ENV['test'] || "test/selenium/selenium_suite")
  end
end

