ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'

require File.expand_path '../../init.rb', __FILE__
require File.expand_path '../../app.rb', __FILE__
