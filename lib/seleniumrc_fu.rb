require 'logger'
require "stringio"

require "active_record"

require 'net/http'
require 'test/unit'

require "polonium"
require "funkytown"
require "seleniumrc_fu/selenium_test_case"

require 'webrick_server' if self.class.const_defined? :RAILS_ROOT
