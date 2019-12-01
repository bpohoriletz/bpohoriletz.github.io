# frozen_string_literal: true

FactoryBot.definition_file_paths << 'domain/spec/factories'
FactoryBot.find_definitions

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
