---
layout: post
post_title: '[EN] Modular Monolith example in Ruby on Rails'
title: '[EN] Modular Monolith example in Ruby on Rails'
description: "Here I've extracted a gem and an engine
from the project into a brand new Rails application and it was painless,
moreover this extraction improved the design of the engine"
---
* Time: 20-30 min
* Level: Intermediate/Advanced
* Code: [GitHub][application]{:target='_blank_'}
* Reference: [The Modular Monolith: Rails Architecture – Dan
Manges][reference]{:target='_blank_'}

Referenced article is among the best I've read in the past year. While I
don't agree with everything stated there, the ideas described are
super awesome (this is when I found out there is a limit on a number of
claps you can give in medium). I've tried to apply them in my pet project
that is built with classic Rails structure - while extraction wasn't easy
the result was definitely worth it. Here I've extracted a gem and an engine
from the project into a brand new Rails application and it was painless,
moreover this extraction improved the design of the engine. I will cover
important pieces of the setup below, but for TLDR people here is a
[Github Repo][application], check the `seed.rb` file for credentials to use.

# Gem Overview #
The gem allows you to fetch event data from a Google Calendar

#### **separation of dependencies** ####
Code in the local gem has it's own dependencies but does not
rely on a main app, these dependencies were moved from the parent app's
Gemfile into a gem's \*.gemspec
{% highlight ruby %}
 # gems/google_calendar/google_calendar.gemspec

 32   spec.add_dependency 'activemodel'
 33   spec.add_dependency 'google-api-client', '~> 0.11'
 34   spec.add_dependency 'ice_cube'
 35   # Development
 36   spec.add_development_dependency 'pry-byebug'
 37   spec.add_development_dependency 'simplecov'
 38   spec.add_development_dependency 'rake'
 39   spec.add_development_dependency 'rspec'
 40   spec.add_development_dependency 'factory_bot'
{% endhighlight %}
and are loaded in initializer
{% highlight ruby %}
  # gems/google_calendar/lib/google_calendar.rb
  1 require 'google/apis/calendar_v3'
  2 require 'google/api_client/client_secrets'
  3
  4 require 'google_calendar/version'
  5 require 'google_calendar/connection'
  6 require 'google_calendar/event'
{% endhighlight %}

#### **separation of tests** ####
All Unit tests for the gem were moved to a gem's folder, they can be
executed independently and in isolation  - navigate to a gems folder
and run `bundle exec rspec spec/`. In order to make tests run you will
need to do a manual setup in helper file
{% highlight ruby %}
  # gems/google_calendar/spec/spec_helper.rb
  1 require 'simplecov'
  2 SimpleCov.start
  3
  4 require 'google_calendar'
  5 require 'factory_bot'
  6 require 'factories/event_factories'
{% endhighlight %}

# Engine Overview #
Engine provides authentication using authlogic gem

#### **separation of dependencies** ####
Same pattern as in gems, all dependencies live in engines \*.gemspec and
do not pollute parent app's Gemfile.
{% highlight ruby %}
 # domains/customers/customers.gemspec
 19   s.add_dependency 'authlogic'
 20   s.add_dependency 'best_in_place', '~> 3.0.1'
 21   s.add_dependency 'draper'
 22   s.add_dependency 'google_calendar'
 23   s.add_dependency 'haml'
 24   s.add_dependency 'rails'
 25
 26   s.add_development_dependency 'rspec-rails'
 27   s.add_development_dependency 'factory_bot'
 28   s.add_development_dependency 'shoulda-matchers'
 29   s.add_development_dependency 'pry-byebug'
 30   s.add_development_dependency 'sqlite3'
{% endhighlight %}
and are loaded in the initializer
{% highlight ruby %}
  # domains/customers/lib/customers.rb
  1 require 'active_model/railtie'
  2 require 'active_record/railtie'
  3 require 'customers/engine'
  4 require 'haml'
  5 require 'best_in_place'
  6 require 'authlogic'
{% endhighlight %}
engine also depends on a local `google_calendar` gem, it is loaded
directly in the Gemfile
{% highlight ruby %}
  # domains/customers/Gemfile
  1 source 'https://rubygems.org'
  2
  3 gem 'google_calendar', path: '../../gems/google_calendar'
{% endhighlight %}

#### **separation of tests** ####
All Unit tests for the engine were moved to a engine's folder, they can be
executed independently and in isolation  - navigate to a engine's dummy
application folder `domains/customers/spec/dummy/` and run `bundle exec rspec spec/`
In order to make tests run you will need to do manual setup of the
environment in the helper file
{% highlight ruby %}
  # domains/customers/spec/dummy/spec/rails_helper.rb
  1 # Configure Rails Environment
  2 ENV['RAILS_ENV'] = 'test'
  3 require File.expand_path("../../config/environment.rb", __FILE__)
  4 # TOFIX ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
  5 ActiveRecord::Migrator.migrations_paths << File.expand_path('../../db/migrate', __FILE__)
  6
  7 require 'rspec/rails'
  8 # Add additional requires below this line. Rails is not loaded until this point!
  9 require 'spec_helper'
 10 require 'authlogic'
 11 require 'authlogic/test_case'
 12 require 'factory_bot'
 13 require 'shoulda-matchers'
 14 require 'pry'
 15
 16 FactoryBot.factories.clear
 17 FactoryBot.definition_file_paths = %W(spec/factories)
 18 FactoryBot.reload
 19 Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
 20
 21 RSpec.configure do |config|
 22   config.include Authlogic::TestCase
 23   config.include FactoryBot::Syntax::Methods
 24   config.include Shoulda::Matchers::ActiveModel, type: :model
 25   config.include Shoulda::Matchers::ActiveRecord, type: :model
 26
 27   config.filter_rails_from_backtrace!
 28 end
{% endhighlight %}

#### **separation of migrations** ####
I believe migration files should not be copied to a parent application,
required configuration is specified in engines initializer
{% highlight ruby %}
  # domains/customers/lib/customers/engine.rb
  1 module Customers
  2   class Engine < ::Rails::Engine
  3     isolate_namespace Customers
  4
  5     initializer :append_migrations do |app|
  6       # Migrations
  7       config.paths['db/migrate'].expanded.each do |expanded_path|
  8         app.config.paths['db/migrate'] << expanded_path
  9       end
          ...
 12     end
 13   end
 14 end
{% endhighlight %}

#### **separation of translations** ####
Translations for views from an engine also live in an engine, configuration is
specified in engines initializer
{% highlight ruby %}
  1 module Customers
  2   class Engine < ::Rails::Engine
  3     isolate_namespace Customers
  4
  5     initializer :append_migrations do |app|
          ...
 10       # Translations
 11       config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.yml"]
 12     end
 13   end
 14 end
{% endhighlight %}
# Enabling authentication in the main application #
Authentication was extracted to be a controllers concern so you need to
add this concern to a controller
{% highlight ruby %}
  # app/controllers/application_controller.rb
  1 class ApplicationController < ActionController::Base
  2   include Customers::Authorization
  3 end
{% endhighlight %}

# Testing Engine/Gem Integration into a main application #
I believe that tests located in engines/gems should be unit tests - they
should run fast and stub any external dependencies. It doesn't make sense
to me to test integration outside of the main applications - System Tests
are great tool to do this job. A basic example
{% highlight ruby %}
# test/system/login_test.rb
  1 require 'application_system_test_case'
  2 require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'accounts', 'login')
  3
  4 class UsersTest < ApplicationSystemTestCase
  5
  6   def test_login_is_functional
  7     load "#{Rails.root}/db/seeds.rb"
  8     ::Pages::Accounts::Login.new(test: self, url: customers.login_url ).instance_eval do
  9       visit
 10       # Validate content
 11       password_present?
 12       login_present?
 13       submit_present?
 14       # Log in
 15       login.set( Customers::Account.first.email )
 16       password.set( 'Test1234' )
 17       submit.click
 18       assert_text( 'Accounts' )
 19     end
 20   ensure
 21     Customers::Account.all.map(&:destroy!)
 22   end
 23 end
{% endhighlight %}

# Summary

Extracting a gem was quite easy, extracting an engine was a bit of work.
Advantages of the Modular Monolith over the classic app:
1. Separation of code - dramatically improved application design
2. Separation of dependencies - keeps main application cleaner
3. Separation of tests - each unit has it's own suite that is fast and
   can be run independently

Code:
* [Repository][application]

# Food for thought
1. How to handle shared layouts?
2. How to handle database tables shared between engines?
3. Should Gemfile.lock from engines/gems exist in the Git repository?


[application]: https://github.com/bpohoriletz/bpohoriletz.github.io/tree/master/samples/modular_monolith_example
[reference]: https://medium.com/@dan_manges/the-modular-monolith-rails-architecture-fb1023826fc4
