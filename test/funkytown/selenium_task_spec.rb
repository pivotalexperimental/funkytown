require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "Basic selenium task setup", :shared => true do
  before do
    @rails_root = "railsroot"
    @rails_env = "originalrailsenv"
    @env = {}
    @task = Funkytown::SeleniumTask.new(@rails_env, @rails_root, @env, :disable_requirement_checking => true)
    @sayings = []
    @task.should_receive(:say).any_number_of_times.and_return do |msg|
      @sayings << msg
    end
  end
end

describe "A selenium task running run_test" do
  it_should_behave_like "Basic selenium task setup"

  it "should check servants, check if the test file exists" do
    @task.stub!(:run_test_on_servant_browsers).and_return(true)
    
    @task.should_receive(:check_servants).once
    @task.should_receive(:find_test_file).once
    @task.run_test
  end

  it "should run tests on each servant host" do
    @task.stub!(:servant_hosts).and_return(["localhost", "another"])
    @task.stub!(:check_servants)
    @task.stub!(:find_test_file).and_return("test/selenium/selenium_suite")

    @task.should_receive(:run_test_on_servant_browsers).ordered.with("test/selenium/selenium_suite", "localhost").and_return(true)
    @task.should_receive(:run_test_on_servant_browsers).ordered.with("test/selenium/selenium_suite", "another").and_return(true)
    @task.run_test
  end

  it "should raise errors if any servant host fails, but run everything anyway" do
    @task.stub!(:servant_hosts).and_return(["localhost", "another"])
    @task.stub!(:check_servants)
    @task.stub!(:find_test_file).and_return("test/selenium/selenium_suite")

    @task.should_receive(:run_test_on_servant_browsers).ordered.with("test/selenium/selenium_suite", "localhost").and_return(false)
    @task.should_receive(:run_test_on_servant_browsers).ordered.with("test/selenium/selenium_suite", "another").and_return(true)
    lambda {@task.run_test}.should raise_error(RuntimeError, "ERROR : Selenium had failed tests")
  end

  it "should pass test name to run_test_on_servant_browsers" do
    @task.stub!(:check_servants)
    @task.stub!(:find_test_file).and_return("test/selenium/my_suite")
    @task.should_receive(:run_test_on_servant_browsers).once.with("test/selenium/my_suite", "localhost").and_return(true)
    @task.run_test("test/selenium/my_suite")
  end
end

describe Funkytown::SeleniumTask do
  it_should_behave_like "Basic selenium task setup"

  it "when passed an absolute path without extension of a file that exists, returns the path" do
    File.should_receive(:exist?).with("railsroot/mytestfile").and_return(false)
    File.should_receive(:exist?).with("railsroot/mytestfile.rb").and_return(true)
    @task.find_test_file("railsroot/mytestfile").should == "railsroot/mytestfile.rb"
  end

  it "when passed an absolute path with extension of a file that exists, returns the path" do
    File.should_receive(:exist?).with("railsroot/mytestfile.rb").and_return(true)
    @task.find_test_file("railsroot/mytestfile.rb").should == "railsroot/mytestfile.rb"
  end

  it "should detect if the test of interest is working" do
    File.should_receive(:exist?).with("mytestfile").and_return(false)
    File.should_receive(:exist?).with("mytestfile.rb").and_return(false)
    File.should_receive(:exist?).with("railsroot/mytestfile.rb").and_return(true)
    @task.find_test_file("mytestfile").should == "railsroot/mytestfile.rb"
  end

  it "should raise an exception if it can't find any files" do
    File.should_receive(:exist?).with("mytestfile").and_return(false)
    File.should_receive(:exist?).with("mytestfile.rb").and_return(false)
    File.should_receive(:exist?).with("railsroot/mytestfile.rb").and_return(false)
    lambda do
      @task.find_test_file("mytestfile")
    end.should raise_error(RuntimeError, "Could not find mytestfile or mytestfile.rb or railsroot/mytestfile.rb")
  end

end

describe "A selenium task running run_test_on_servant_browsers" do
  it_should_behave_like "Basic selenium task setup"

  before(:each) do
    @task.stub!(:rake_command).and_return("rakecommand")
  end

  def stub_and_record_run_passing_system_cmd
    @cmd = nil
    @task.should_receive(:run_system_cmd).and_return do |cmd|
      @cmd = cmd
      true
    end
  end

  it "should pass the test name and standard environmental args to the rake task it runs" do
    stub_and_record_run_passing_system_cmd
    @task.run_test_on_servant_browsers("mytest", "localhost")
    @cmd.starts_with?("rakecommand selenium:test_with_server_started --trace test=mytest").should be_true
  end

  it "should pass standard environmental args to the rake task it runs" do
    stub_and_record_run_passing_system_cmd
    @task.run_test_on_servant_browsers("mytest", "localhost")
    @cmd.include?("browsers=firefox").should be_true
    @cmd.include?("selenium_server_host=localhost").should be_true
    @cmd.include?("internal_app_server_host=0.0.0.0").should be_true
    @cmd.include?("external_app_server_host=localhost").should be_true
  end

  it "should allow environment overrides" do
    stub_and_record_run_passing_system_cmd
    @task.env = {"browsers" => "iexplore", "internal_app_server_host" => "foobar", "external_app_server_host" => "foobar"}

    @task.run_test_on_servant_browsers("mytest", "localhost")
    @cmd.include?("browsers=iexplore").should be_true
    @cmd.include?("internal_app_server_host=foobar").should be_true
    @cmd.include?("external_app_server_host=foobar").should be_true
  end

  it "should return false and say an error if the system command returns false" do
    @task.stub!(:run_system_cmd).and_return(false)
    @task.run_test_on_servant_browsers("mytest", "localhost").should be_false
    @sayings.last.should include("SELENIUM FAILURE OCCURRED")
  end
end
