---
layout: post
post_title: '[UA] Предметно-орієнтована архітектура Rails'
title: '[UA] Предметно-орієнтована архітектура Rails'
description: 'Дана стаття описує структуру проекту написаного на Rails і в ній
використані ідеї з DDD та зазначених статтей. Окрім того приклад містить в
собі можливість досить просто використовувати автоматичні додатки для
перевірки якості коду.'
---
* Час: 20-30 хвилин
* Рівень: Середній/Просунутий
* Код: [GitHub][application]
* Ресурси:
  * [The Modular Monolith: Rails Architecture – Dan Manges][mm_reference]{:target='_blank_'}
  * [Counterintuitive Rails - Ivan Nemytchenko][cir_reference]{:target='_blank_'}
  * [Rails Parts – Tom Rothe][rp_reference]{:target='_blank_'}
  * [Scaling Teams using Tests for Productivity and Education - Julian Nadeau][st_reference]{:target='_blank_'}

Дана стаття описує структуру проекту написаного на Rails і в ній
використані ідеї з вищезазначених статтей. Окрім того приклад містить в
собі можливість досить просто використовувати автоматичні додатки для
перевірки якості коду. Головними вимогами до проекту є:
  1. Розділення перегляду (репрезентації) та бізнес-логіки (вашого домену)
  2. Розділення залежностей (gems) і як результат - можливість
     виконувати юніт тести в ізольованому середовищі
  3. Рішення повинно бути простим і зрозумілим (Rails чудовий фреймворк
     і ми не збираємось з ним боротись)

TLDR - [Github repo][application] та [commit][commit] з усіма змінами
застосованими до нового проекту на Rails

# **Розділення перегляду та бізнес-логіки** #
Першим кроком є чітке розділення перегляду та бізнес-логіки в структурі
проекту (та в вашій голові). Для досягнення даного результату ми
створимо нову папку `representations/` і перемістимо в неї все що нам
потрібно для того щоб показати суб'єкти домену. В прикладі ними є:
  - `representations/`
    - `assets/`
    - `controllers/`
    - `decorators/`
    - `public/`
    - `views/`
    - `vendor/`
    - `routes.rb`

> Я надаю перевагу використанню декораторів замість helper тому тут немає папки
 `helpers/`.

Далі нам потрібно побудувати структуру тек для суб'єктів та логіки домену
- жодне з цих двох понять не повинно бути присутнім в частині проекту,
що відповідає за представлення. Отож давайте створимо нову теку `domain/`і перемістимо
в неї моделі та налаштування для бази даних:
  - `domain/`
    - `contexts/`
    - `database.yml`

Назва `contexts/` тут є посиланням на шаблон [Bounded Context][bc_reference] в теорії
Предметно-орієнтованого програмування. Ви можете назвати їх по-іншому і мати будь-яку структуру
тек всередині.

Тепер нам потрібно налаштувати Rails для роботи з новою структурою тек. Дані налаштування
знаходяться всередині файлу `config/application.rb` і використовують API [Rails::Application][rap_reference]

{% highlight ruby %}
 # config/application.rb

 28     paths[ 'app/assets' ]         = 'representations/assets'
 29     paths[ 'app/views' ]          = 'representations/views'
 30     paths[ 'config/routes.rb' ]   = 'representations/routes.rb'
 31     paths[ 'config/database' ]    = 'domain/database.yml'
 32     paths[ 'public' ]             = 'representations/public'
 33     paths[ 'public/javascripts' ] = 'representations/public/javascripts'
 34     paths[ 'public/stylesheets' ] = 'representations/public/stylesheets'
 35     paths[ 'vendor' ]             = 'representations/vendor'
 36     paths[ 'vendor/assets' ]      = 'representations/vendor/assets'
 37     # impacts where Rails will look for an ApplicationController and ApplicationRecord
 38     paths[ 'app/controllers' ] = 'representations/controllers'
 39     paths[ 'app/models' ]      = 'domain/contexts'
 40
 41     %W[
 42       #{ File.expand_path( '../representations/concerns', __dir__ ) }
 43       #{ File.expand_path( '../representations/controllers', __dir__ ) }
 44       #{ File.expand_path( '../domain/concerns', __dir__ ) }
 45       #{ File.expand_path( '../domain/contexts', __dir__ ) }
 46     ].each do |path|
 47       config.autoload_paths   << path
 48       config.eager_load_paths << path
 49     end

{% endhighlight %}

Після цієї зміни Rails буде працювати з новою структурою тек так, ніби оригінальна ніколи не змінювалась -
autoloading, eager loading, asset compilation - всі ці процеси будуть повністю функціональні.

> На мою особисту думку представлення `ApplicationController` та `ApplicationRecord` як `Concern`
> покращує гнучкість коду, тому в даному прикладі вони є `Concerns` і є додатковий файл `config/initializers/draper.rb`
> для того щоб 'Draper' зміг з ними працювати

{% highlight ruby %}
 # config/initializers/draper.rb

 3 DraperBaseController = Class.new( ActionController::Base )
 4 DraperBaseController.include( ApplicationController )
 5
 6 Draper.configure do |config|
 7   config.default_controller = DraperBaseController
 8 end
{% endhighlight %}

# **Розділення середовищ та побудова незалежних тестів** #

Раніше ми розділили представлення і предметну область, тепер окремі тести для
кожної частини будуть великим плюсом для проекту. Правильного написані тести будуть
швидші, ізольовані та незалежні. Спершу підготуємо середовище для них:
  1. Створимо окремі `Gemfile` та `Gemfile.lock` для представлення та предметної області
  2. Налаштовуємо головний `Gemfile` так щоб він використовував нові специфічні для кожної
     області `Gemfile`
  3. Налаштуємо незалежні тестові середовища для представлення та предметної області

Додавання додаткових `Gemfile` не є чимось складним - ми просто створюємо нові файли і переміщуємо
в них залежності (gem) з головного.

Налаштувати головний `Gemfile` для роботи з розподіленими залежностями є також доволі простим - `bundler`
вже має метод для завантаження додаткових файлів, якщо виникнуть проблеми при завантаженні розподілених
залежностей ви побачите ті самі помилки що і при завантаженні звичайного `Gemfile`

{% highlight ruby %}
 # Gemfile

 54 %w[ representations/Gemfile domain/Gemfile ].each do |custom_gemfile|
 55   eval_gemfile custom_gemfile
 56 end
{% endhighlight %}

Налаштування незалежних тестових середовищ є найскладнішою частиною (і найімовірніше саме тут виникнуть
додаткові проблеми при рості проекту). Перший крок - запустити команду `rspec --init` в теках `representations/`
та `domain/`. В результаті нові таки `representations/spec` та `domain/spec` будуть додані.

`spec/spec_helper.rb` також буде додано автоматично, проте `spec/rails_helper.rb` автоматично створено
не буде і нам доведеться додати і налаштувати його вручну.

#### Налаштування тестового середовища предметної області ####

Для початку ми копіюємо файл `spec/rails_helper.rb` в `domain/spec/rails_helper.rb` і видаляємо з нього все до лінії
`RSpec.configure do |config|`. Це робиться для того щоб не завантажувати жодних залежностей - ми їх завантажимо
вручну пізніше. Після цього в нас не буде можливості запустити тести, проте це лише перший крок.

Далі ми завантажуємо всі необхідні залежності:

- завантажуємо `active_record` та `rspec-rails`
{% highlight ruby %}
  # domain/spec/rails_helper.rb

  3 require 'active_record/railtie'
  4 require 'active_support'
  5 require 'rspec/rails'
{% endhighlight %}
- завантажуємо залежності тестового середовища
{% highlight ruby %}
  7 ENV['RAILS_ENV'] ||= 'test'
  8 require 'spec_helper'
  9 require 'database_cleaner'
 10 require 'factory_bot'
 11 require 'pry-byebug'
{% endhighlight %}
- створюємо Application для роботи з `rspec-rails` (нажаль найбільш
слабка частина)
{% highlight ruby %}
 13 ContextsTestApplication = Class.new( ::Rails::Application )
 14 ::Rails.application = ContextsTestApplication.new
{% endhighlight %}
- під'єднуємось до бази даних
{% highlight ruby %}
 16 database_configurations = YAML.load(
 17   ERB.new(
 18     File.read( File.expand_path( '../database.yml', __dir__ ) )
 19   ).result
 20 )
 21
 22 ActiveRecord::Base.establish_connection( database_configurations[ 'test' ] )
 23
{% endhighlight %}
- завантажуємо предметну область (спільні concerns в першу чергу оскільки немає
механізму автозавантаження)
{% highlight ruby %}
 24 %w[ concerns contexts ].each do |folder|
 25   Dir[ File.expand_path( "../#{folder}/**/*.rb", __dir__ ) ].each { |f| require f }
 26 end
{% endhighlight %}
- завантаження файлів initializer/support
{% highlight ruby %}
 28 Dir[ './spec/support/*.rb' ].each { |f| require f }
 29
 30 RSpec.configure do |config|
{% endhighlight %}

#### налаштування тестового середовища для представлення ####

Налаштування тестового середовища для представлення є досить схожим -
єдина різниця це залежності якими завантажуємо:

- завантажуємо `action_controller` та `rspec-rails`
{% highlight ruby %}
  # representations/spec/rails_helper.rb
  3 require 'action_controller/railtie'
  4 require 'active_support'
  5 require 'rspec/rails'
  6 require 'spec_helper'
{% endhighlight %}
- створюємо Application для `rspec-rails` та завантажуємо routes
{% highlight ruby %}
  8 RepresentationsTestApplication = Class.new( ::Rails::Application )
  9 ::Rails.application = RepresentationsTestApplication.new
 10 require_relative '../routes'
{% endhighlight %}
- завантажуємо залежності
{% highlight ruby %}
 12 require 'pry-byebug'
 13 require 'uuid'
{% endhighlight %}
- завантажуємо код представлення (спільні concerns в першу чергу оскільки немає
механізму автозавантаження)
{% highlight ruby %}
 15 %w[ concerns controllers decorators ].each do |folder|
 16   Dir[ File.expand_path( "../#{folder}/**/*.rb", __dir__ ) ].each { |f| require f }
 17 end
{% endhighlight %}

Тепер у нас є змога запускати різні тести в залежності від контексту і для кожного контексту:
 - тести можуть включати лише юніт-тести
 - ми змушені залишатися всередині контексту при написанні тесту
 - завантаження/перезавантаження середовища є швидким (завантаження файлів тривало 2.65 секунди коли тести
   запускалося з головного проекту і лише 0.9 секунд якщо запускалась незалежно)

> Оскільки файли налаштування тестового середовища знаходяться всередині тек `representations/` та `domain/`,
> ці тeки не можуть бути всередині `app/` - тому що Rails спробує завантажити ці файли в production.

# **Фінальні частини** #

Як я вже згадував у [попередній][mon_reference] статті, я вважаю що тести,
що знаходяться в головній теці `spec/`, `test/` не повинні бути юніт-тестами
і завжди тестувати декілька компонентів проекту. Протилежне твердження є
істинним для тестів що знаходяться в теках `representations/spec/` та `domain/spec`
завжди повинні бути юніт-тестами.

Одна проблема з даним налаштуванням є те що для того щоб запускати тести
всередині ізольованого середовища ви повинні мати окремі `Gemfile.lock` і це може
спричинити різницю у версіях gem які використовується для тестів що запускаються в
ізоляції і тестів що допускаються як частина глобальної тестової системи. Давайте
напишемо тест який би нам повідомляв якщо така ситуація станеться:

{% highlight ruby %}
  # spec/sanity/gemfile_spec.rb

  5 RSpec.describe 'Gemfile' do
  6   context 'Domain Gemfile' do
  7     it 'have gems locked at the same version as a global Gemfile' do
  8       global_environment = Bundler::Dsl.evaluate( 'Gemfile', 'Gemfile.lock', {} )
  9                                        .resolve
 10                                        .to_hash
 11       local_environment = Bundler::Dsl.evaluate( 'domain/Gemfile', 'domain/Gemfile.lock', {} )
 12                                       .resolve
 13                                       .to_hash
 14
 15       diff = local_environment.reject do |gem, specifications|
 16         global_environment[ gem ].map( &:version ).uniq == specifications.map( &:version ).uniq
 17       end
 18
 19       expect( diff.keys ).to eq( [] )
 20     end
 21   end
{% endhighlight %}

[Приклад][application] проекту також включає Git hooks які будуть встановлені
на ваш проект якщо ви запустите `./bin/setup` і будуть автоматично виконані перед
та після того як ви зробити commit. pre-commit hook запускає rubocop для перевірки
всіх змін які будуть включені в commit, post-commit hook надає вам можливість запускати
rails_best_practices, reek, brakeman і mutant для вашого коду.

# **Підсумок** #

Мені дуже подобається гнучкість даної архітектури - при потребі можна заізолювати будь-яку
частину коду і ставитись до неї як до незалежного unit. В той же час вона, здебільшого,
використовує Rails API - тож ми не боремося з Rails, скоріше це ще один спосіб для організації
коду. Мені кортить випробувати дану архітектуру з більш складними та legacy проектами - її
застосування повинно бути доволі простим в обох випадках.

Посилання:
 * [Проект][application]
 * [Commit][commit]


[application]: https://github.com/bpohoriletz/bpohoriletz.github.io/tree/master/samples/domain_driven_rails_architecture_pattern
[commit]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/51220e7f4274e35cf6c071a0cf3ba683dd2af938
[mm_reference]: https://medium.com/@dan_manges/the-modular-monolith-rails-architecture-fb1023826fc4
[cir_reference]: https://www.youtube.com/watch?v=KtD32fO_owU&index=4&list=PLqwEgoaqsYziFoM8UN2GmWc0BySnWUozK
[rp_reference]: http://tomrothe.de/posts/rails_parts.html
[st_reference]: https://www.youtube.com/watch?v=InFnu8bYi6s&list=PoLqwEgoaqsYziFoM8UN2GmWc0BySnWUozK
[bc_reference]: https://martinfowler.com/bliki/BoundedContext.html
[rap_reference]: https://api.rubyonrails.org/classes/Rails/Application/Configuration.html#method-i-paths
[mon_reference]: https://bpohoriletz.github.io/2018/06/23/modular-monolith-example.html
