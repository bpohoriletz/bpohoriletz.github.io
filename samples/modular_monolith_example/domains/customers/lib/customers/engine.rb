module Customers
  class Engine < ::Rails::Engine
    isolate_namespace Customers

    initializer :append_migrations do |app|
      # Migrations
      config.paths['db/migrate'].expanded.each do |expanded_path|
        app.config.paths['db/migrate'] << expanded_path
      end
      # Translations
      config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.yml"]
    end
  end
end
