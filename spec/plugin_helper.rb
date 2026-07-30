# frozen_string_literal: true
## The plugin store is not wiped between each test

require "webmock/rspec"

RSpec.configure do |config|
  config.before(:each) do
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    Multilingual::ContentTag.reset_groups
  end

  config.after(:each) { ActiveRecord::Base.connection.rollback_transaction }

  config.around(:each) { |example| allow_missing_translations { example.run } }
end

require "rails_helper"
