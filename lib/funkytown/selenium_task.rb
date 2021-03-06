require 'funkytown/funkytown_task'

module Funkytown
  class SeleniumTask < FunkytownTask

    attr_accessor :selenium_servants

    def initialize(rails_env = RAILS_ENV, rails_root = RAILS_ROOT, env = ENV, options = {})
      @disable_requirement_checking = true if options[:disable_requirement_checking]
      super(rails_env, rails_root, env, options)
      check_requirements
    end

    def check_requirements
    end
    ###### actions

    def run_test(test_name = "test/selenium/selenium_suite")
      check_servants
      corrected_filename = find_test_file(test_name)

      anything_failed = false
      servant_hosts.each do |servant_host|
        ok = run_test_on_servant_browsers(corrected_filename, servant_host)
        anything_failed = true unless ok
      end
      raise "ERROR : Selenium had failed tests" if anything_failed
    end

    def run_test_on_servant_browsers(test_name, servant_host)
      browsers = @selenium_servants[servant_host]["browsers"].join(",")
      rake_env = {
        "browsers" => browsers,
        "selenium_server_host" => servant_host,
        "selenium_server_port" => servant_port(servant_host),
        "external_app_server_host" => @external_app_server_host,
        "external_app_server_port" => @external_app_server_port,
        "internal_app_server_host" => @internal_app_server_host,
        "internal_app_server_port" => @internal_app_server_port,
        "app_server_engine" => @app_server_engine,
        "verify_remote_app_server_is_running" => @verify_remote_app_server_is_running,
        "keep_browser_open_on_failure" => @keep_browser_open_on_failure
      }.merge(env)

      cmd ="#{rake_command} selenium:test_with_server_started --trace test=#{test_name}"
      env_string = parameterize_env_variables(['browsers', 'selenium_server_host', 'selenium_server_port',
                    'internal_app_server_host', 'internal_app_server_port', 'keep_browser_open_on_failure',
                    'app_server_engine', 'external_app_server_host', 'external_app_server_port',
                    'verify_remote_app_server_is_running'], rake_env)
      cmd << " " << env_string unless env_string.empty?

      say cmd
      # TODO: use System::Process instead of Kernel::system
      ok = run_system_cmd(cmd)
      if !ok
        say <<-EOL

  SELENIUM FAILURE OCCURRED :
    browsers = '#{browsers}'
    selenium_server_host = '#{servant_host}'
    external_app_server_host = '#{@external_app_server_host}'
    internal_app_server_host = '#{@internal_app_server_host}'
    cmd = '#{cmd}'
        EOL
      end
      return ok
    end

    def servant_cmd(selenium_host)
      cmd = "selenium-rc #{@servant_options}"
      say "Using servant command: #{cmd}"
      cmd
#
#      cmd = "#{rake_command} selenium:run_server"
#
#      rake_env = env
#
#      cmd = "#{rake_command} selenium:run_server"
#      env_string = parameterize_env_variables(['selenium_server_jar'], rake_env)
#      cmd << " " << env_string unless env_string.empty?
#
#      cmd
    end

    def parameterize_env_variables(allowed_params, env)
      env_commands = []
      allowed_params.each do |name|
        env_commands << "#{name}=#{env[name]}" if env[name]
      end
      env_commands.join(" ")
    end

    def servant_name(servant_host)
      "selenium_servant"
    end

    def servant_port(servant_host)
      @selenium_servants[servant_host]["port"]
    end

    def debug?
      env["selenium_verbose"]
    end

    def run_system_cmd(cmd)
      system(cmd)
    end

    def servant_hosts
      @selenium_servants.keys
    end

    ############################
    # Helper methods
    ############################

    def find_test_file(test_name)
      paths_to_attempt = [
        test_name,
        "#{test_name}.rb",
        "#{rails_root}/#{test_name}.rb"
      ]

      paths_to_attempt.each do |path|
        return path if File.exist?(path)
      end
      
      raise "Could not find #{paths_to_attempt.join(' or ')}"
    end

    def windows?
      RUBY_PLATFORM =~ /mswin32/
    end

    def rake_command
      windows? ? "rake.bat" : "rake"
    end

  end
end
