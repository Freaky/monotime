$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

unless RUBY_ENGINE=='truffleruby'
  require 'simplecov'
  SimpleCov.start
end

require 'monotime'

require 'minitest/autorun'
