# frozen_string_literal: true
## The plugin store is not wiped between each test

require 'webmock/rspec'

RSpec.configure do |config|
  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start do
    root "plugins/discourse-multilingual"
    track_files "plugins/discourse-multilingual/**/*.rb"
    add_filter { |src| src.filename =~ /(\/spec\/|\/db\/|plugin\.rb|gems)/ }
    SimpleCov.minimum_coverage 80
  end
end

require 'rails_helper'
