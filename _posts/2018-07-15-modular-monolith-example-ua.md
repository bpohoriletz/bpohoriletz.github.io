---
layout: post
post_title: '[UA] Приклад архітектури Модульний Моноліт в Ruby on Rails'
---
* Time: 20-30 min
* Level: Intermediate/Advanced
* Code: [GitHub][application]{:target='_blank_'}
* Reference: [The Modular Monolith: Rails Architecture – Dan
Manges][reference]{:target='_blank_'}

Вищезгадана стаття є однією з найкращих, яку я прочитав у минулому році. Я
не погоджуюсь з усіма правилами поданими в ній, проте описані ідеї
є надзвичайно цікавими (саме після прочитання її я дізнався, що є обмеження на кількість
оплесків, які ви можете дати). Я спробував застосувати їх у моєму проекті
що був збудований за класичною архітектурою Rails - перебудувати проект було нелегко, проте
результат був безумовно того вартий. Нижче я опишу важливі частини створення локальних gem та engine
в проекті, але для TLDR читачів ось є
[Github Repo][application], в файлі `seed.rb` знаходяться логін і пароль.

# Огляд Gem #
Локальний gem дозволяє отримати дані про події з Google Calendar

#### **розділення залежностей** ####

Код в локальному gem має внутрішні залежності, проте повністю незалежний
від проекту в якому використовується. Раніше всі залежності знаходились
в Gemfile батьківського проекту проте були переміщені в файл \*.gemspec
всередині gem.

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
і завантажуються в initializer
{% highlight ruby %}
  # gems/google_calendar/lib/google_calendar.rb
  1 require 'google/apis/calendar_v3'
  2 require 'google/api_client/client_secrets'
  3
  4 require 'google_calendar/version'
  5 require 'google_calendar/connection'
  6 require 'google_calendar/event'
{% endhighlight %}

#### **розділення тестів** ####

Всі залежні юніт тести були переміщені з батьківського проекту в папку з
локальним gem, їх можна запускати незалежно та ізольовано від
батьківського проекту - перейдіть до папки з gem та запустіть `bundle
exec rspec spec/`. Необхідні налаштування показано нижче:
{% highlight ruby %}
  # gems/google_calendar/spec/spec_helper.rb
  1 require 'simplecov'
  2 SimpleCov.start
  3
  4 require 'google_calendar'
  5 require 'factory_bot'
  6 require 'factories/event_factories'
{% endhighlight %}

# Огляд Engine #
Engine надає можливість аутентифікації за допомогою authlogic

#### **розділення залежностей** ####
Процес такий же як і для gems, всі залежності перенесено в файл \*.gemspec
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
їх завантаження відбувається в initializer
{% highlight ruby %}
  # domains/customers/lib/customers.rb
  1 require 'active_model/railtie'
  2 require 'active_record/railtie'
  3 require 'customers/engine'
  4 require 'haml'
  5 require 'best_in_place'
  6 require 'authlogic'
{% endhighlight %}
engine використовує локальний gem `google_calendar`, його потрібно
завантажити в Gemfile
{% highlight ruby %}
  # domains/customers/Gemfile
  1 source 'https://rubygems.org'
  2
  3 gem 'google_calendar', path: '../../gems/google_calendar'
{% endhighlight %}

#### **розділення тестів** ####
Всі юніт тести для engine було переміщено в папку з engine, їх можна
запустити незалежно від основного проекту - перейдіть в папку з тестами
для engine `domains/customers/spec/dummy/` і запустіть `bundle exec rspec spec/`
Налаштування test sute знаходяться в `rails_helper.rb`
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

#### **розділення migrations** ####
Я вважаю міграції не повинні копіюватись до батьківського проекту,
необхідні налаштування знаходяться в initializer
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

#### **розділення локалізацій** ####
Файли з локалізацією можна помістити в папку з engine, налаштування
знаходяться в файлі initializer
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
# Використання аутентифікації в батьківському проекті #
Аутентифікація була винесена в concern отож потрібно використати цей concern у controller
{% highlight ruby %}
  # app/controllers/application_controller.rb
  1 class ApplicationController < ActionController::Base
  2   include Customers::Authorization
  3 end
{% endhighlight %}

# Тестування Engine/Gem в батьківському проекті #
Я вважаю, що тести, розташовані в engine/gem, повинні бути юніт тестами - вони
повинні швидко запускатись і використовувати stub замість будь-яких зовнішніх залежностей.
Коли потрібно протестувати інтеграцію з іншими engine/gem - використати системні тести.
Приклад:
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

# Висновки

Винести gem було досить легко, винести engine було трохи складніше.
Переваги модульного моноліту над класичним:
1. Розділення коду - значно вдосконалений дизайн
2. Розділення залежностей
3. Розділення тестів - кожен engine/gem має власні тести, які швидко працюють
    і можуть запускатись незалежно

Код:
* [Git][application]

# Подумати:
1. Чи можна використовувати shared layouts?
2. Що робити коли потрібно мати доступ до однієї таблиці з різних engine?
3. Чи потрібно Gemfile.lock з engines/gems додавати в Git?


[application]: https://github.com/bpohoriletz/bpohoriletz.github.io/tree/master/samples/modular_monolith_example
[reference]: https://medium.com/@dan_manges/the-modular-monolith-rails-architecture-fb1023826fc4
