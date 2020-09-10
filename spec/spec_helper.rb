require "bundler/setup"
require "has_filters"
require "active_record"
require "rspec/collection_matchers"
require "is_dynamically_expected"
require "database_cleaner/active_record"

DB_CONFIGS = YAML.load_file(File.join(File.dirname(__FILE__), "database.yml")).freeze

RSpec.configure do |config|
  DatabaseCleaner.strategy = :transaction

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include IsDynamicallyExpected

  config.before(:suite) do
    ActiveRecord::Base.establish_connection DB_CONFIGS["postgresql"]

    ActiveRecord::Base.connection.drop_database("has_filters_postgresql_test")
    ActiveRecord::Base.connection.create_database("has_filters_postgresql_test")
  end

  config.after(:suite) do
    ActiveRecord::Base.connection.drop_database("has_filters_postgresql_test")
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
