---
layout: post
post_title: '[UA] ООП та системні тести в Ruby on Rails'
---
* Час: 30-40 min
* Рівень: Середній/Високий
* Код: [GitHub][application]

В цій статті ми на простому прикладі розглянемо як можна покращити
`Rails 5.1.3 System Test` використовуючи Plain Old Ruby Objects,
collaborators, delegators і module.

# Крок #0
Приклад до рефакторингу
{% highlight ruby %}
# test/system/users_test.rb
require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit users_url

    assert_selector "h1", text: "User"
  end

  test 'creating new user' do
    visit users_url
    click_on 'New User'
    fill_in 'First name', with: 'Bill'
    fill_in 'Last name', with: 'Bird'
    click_on 'Create User'
    visit users_url
    assert_text 'Bill Bird'
  end

  test 'editing existing user' do
    User.new(first_name: 'Bill', last_name: 'Bird').save
    visit edit_user_url(User.first)
    fill_in 'First name', with: 'First'
    fill_in 'Last name', with: 'Last'
    click_on 'Update User'
    assert_text 'First Last'
  end
end
{% endhighlight %}
Тест перевіряє три речі:
1. Чи можливо відкрити сторінку зі списком користувачів і чи має вона очікувану структуру
2. Чи можливо додати нового користувача і чи буде новий користувач на сторінці зі списком користувачів
3. Чи можливо оновити інформацію про користувача і чи будуть відображені зімни на сторінці зі списком користувачів

# Крок #1
В цьому кроці ми:
1. Створимо новий абстрактний клас який в майбутньому допоможе нам описати структуру та функціонал HTML сторінок
2. Створимо page class для тестування сторінки з інформацією про користувача
3. Використаємо новий page class в тесті

Для початку ми додамо абстрактний клас, який має один метод для визначення елементів на сторінці, зміни можна переглянути у [відповідному комміті][step-one]
{% highlight ruby %}
# test/support/pages/base.rb
module Pages
  class Base
    Error = Class.new(StandardError)
    attr_reader :current_session
    attr_reader :url

    def self.has_node(method_name, selector, default_selector = :css, options = {})
      case default_selector
      when :css
        define_method(method_name) do
          css_selector = @css_wrapper + ' ' + selector
          current_session.first(default_selector, css_selector.strip, options)
        end
      when :xpath
        # XPATH accessor
        define_method(method_name) do
          current_session.first(default_selector, selector, options)
        end
      else
        fail Error, "Unknown selector #{default_selector}"
      end
    end

    private

    # initialize with Capybara session
    def initialize(url:, css_wrapper: ' ', current_session: Capybara.current_session)
      @current_session = current_session
      @url = url
      @css_wrapper = css_wrapper
    end
  end
end
{% endhighlight %}
Давайте детальніше розглянемо метод `initilaize` та instance variables у ньому:
* `@current_session` - за замовчуванням `Capybara.current_session`,
об'єкт-collaboratior що дозволяє нам використовувати driver всередині методу `has_node`
* `@url` - обов'язкова змінна, URL сторінки що тестується
* `@css_wrapper` - за замовчуванням порожня стрічка, допоміжний параметр, використовується коли всі елементи на сторінці знаходяться всередині елементу з певним CSS класом

Тепер додамо новий клас що описує сторінку з інформацією про користувача
{% highlight ruby %}
# test/support/pages/users/show.rb
require_relative '../base'

module Pages
  module Users
    class Show < Pages::Base
      has_node :notice, '#notice'
      has_node :edit_user_link, 'a', :css, text: 'Edit'
      has_node :back_link, '//a[text()="Back"]', :xpath
    end
  end
end
{% endhighlight %}
Є три способи для визначення елементу на сторінці:
1. За CSS id
2. За типом і текстом всередині елементу
3. За xpath

Варто запам'ятати:
* `has_node` лише обгортка навколо
[Capybara::Node::Finders#first][node-element-first] тому є різні способи отримати один і той же результат
* `has_node` повертає такий же результат що й  [Capybara::Node::Finders#first][node-element-first], якщо елемент був знайдений то це об'єкт [Capybara::Node::Element][node-element]


Тепер використаємо `Pages::Users::Show` в тесті для  `UsersController#show`
{% highlight ruby %}

  test 'creating new user' do
    visit users_url
    click_on 'New User'
    fill_in 'First name', with: 'Bill'
    fill_in 'Last name', with: 'Bird'
    click_on 'Create User'

    page = ::Pages::Users::Show.new(url: user_path(User.last))
    assert page.notice.text == 'User was successfully created.'
    assert page.edit_user_link.text == 'Edit'
    assert page.back_link.text == 'Back'

    visit users_url
    assert_text 'Bill Bird'
  end

{% endhighlight %}
цей крок досить малий, лише для того щоб зрозуміти як використовувати page classes

# Крок #2
В цьому кроці ми:
1. Додамо новий `Pages::Base#visit` метод
2. Додамо `Rails.application.routes.url_helpers` до `Pages::Base` для того щоб мати доступ до routes
3. Додамо `Pages::Users::New`, `Pages::Users::Edit`, `Pages::Users::Index`
4. Використаємо нові класи для рефакторингу

Я не додаватиму код нових класів тут, його можна знайти у [відповідному комміті][step-two]. Натомість давайте поглянемо на тест, що їх використовує:
{% highlight ruby %}
# test/system/users_test.rb
require 'application_system_test_case'
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'show')
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'new')
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'index')
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'edit')

class UsersTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit users_url

    assert_selector "h1", text: "User"
  end

  test 'creating new user' do
    ::Pages::Users::Index.new.instance_eval do
      visit
      new_user_link.click
    end

    ::Pages::Users::New.new.instance_eval do
      visit
      first_name.set( 'Bill' )
      last_name.set( 'Bird' )
      create_user_button.click
    end

    page = ::Pages::Users::Show.new(url: user_path(User.last))
    assert page.notice.text == 'User was successfully created.'
    assert page.edit_user_link.text == 'Edit'
    assert page.back_link.text == 'Back'

    ::Pages::Users::Index.new.visit
    assert_text 'Bill Bird'
  end

  test 'editing existing user' do
    User.new(first_name: 'Bill', last_name: 'Bird').save

    ::Pages::Users::Edit.new(url: edit_user_url(User.first)).instance_eval do
      visit
      first_name.set( 'First' )
      last_name.set( 'Last' )
      update_user_button.click
    end

    ::Pages::Users::Index.new.visit
    assert_text 'First Last'
  end
end
{% endhighlight %}
У нас лишилось ще три кроки попереду проте давайте підсумуємо що ми вже отримали:
1. Ми використовуємо методи класу а не CSS/XPATH отож якщо структура сторінки зміниться ми повинні будемо змінити лише клас щоб виправити тести
2. Завдяки використанню collaborator objects код згрупований всередині блоків, його простіше зрозуміти і одразу очевидно на якій сторінці виконується кожна лінія коду

# Крок #3
В цьому кроці ми:
1. Додамо можливість перевіряти чи присутній елемент всередині page classes
2. Додамо у  `Pages::Users::Show` метод для перевірки структури сторінки

Для початку розглянемо зміни в тесті ( всі зміни у [відповідному комміті][step-three])

#### До
{% highlight ruby %}
  # test/system/users_test.rb
  test 'creating new user' do
    # Not important piece
    page = ::Pages::Users::Show.new(url: user_path(User.last))
    assert page.notice.text == 'User was successfully created.'
    assert page.edit_user_link.text == 'Edit'
    assert page.back_link.text == 'Back'

    ::Pages::Users::Index.new.visit
    assert_text 'Bill Bird'
  end
{% endhighlight %}

#### Після
{% highlight ruby %}
  # test/system/users_test.rb
  test 'creating new user' do
    # Not important piece
    ::Pages::Users::Show.new(test: self, url: user_path(User.last)).instance_eval do
      check_main_elements_presence
      assert notice.text == 'User was successfully created.'
    end

    ::Pages::Users::Index.new.visit
    assert_text 'Bill Bird'
  end
{% endhighlight %}

Метод `Pages::Users::Show#check_main_elements_presence`
{% highlight ruby %}
  # test/support/pages/users/show.rb
  def check_main_elements_presence
    notice_present?
    edit_user_link_present?
    back_link_present?
  end
{% endhighlight %}
Для отримання такого результату ми:
1. Змінили `Pages::Base#initialize` - тепер він очікує новий об'єкт-collaborator  `test:`
2. Змінили `Pages::Base#has_node` - тепер він додає метод для доступу до елементу та перевірки наявності елементу на сторінці -  `*_present?`

# Крок #4
В цьому кроці ми вилучимо спільний функціонал у модуль ([відповідний комміт][step-four])

Для початку порівняємо `Pages::User::Edit` та `Pages::User::New`
{% highlight ruby %}
  # pages/user/edit.rb
  require_relative '../base'
  module Pages
    module Users
      class Edit < Pages::Base
        has_node :first_name,         '#user_first_name'
        has_node :last_name,          '#user_last_name'
        has_node :update_user_button, '//input[@value ="Update User"]', :xpath
      end
    end
  end

  # pages/user/new.rb
  require_relative '../base'
  module Pages
    module Users
      class New < Pages::Base
        has_node :first_name,         '#user_first_name'
        has_node :last_name,          '#user_last_name'
        has_node :create_user_button, '//input[@value= "Create User"]', :xpath

      private

        def http_path
          new_user_path
        end
      end
    end
  end
{% endhighlight %}
обидва мають однакові елементи `first_name` та `last_name`, що не дивно - ми render один і той самий partial `form` на  обох сторінках. Окрім того ми заповнюємо цю форму коли тестуємо ці сторінки. Давайте вилучимо спільний функціонал у модуль.

#### `Pages::Users::Partials::UserForm` модуль
{% highlight ruby %}
# test/support/pages/users/partials/user_form.rb
module Pages
  module Users
    module Partials
      module UserForm
        def self.included(clazz)
          clazz.has_node :first_name,         '#user_first_name'
          clazz.has_node :last_name,          '#user_last_name'
        end

        def fill_out_user_form(first: 'Bill', last: 'Bird')
          first_name.set(first)
          last_name.set(last)
        end
      end
    end
  end
end
{% endhighlight %}
#### Page classes після рефакторингу
{% highlight ruby %}
  # pages/user/edit.rb
  require_relative '../base'
  module Pages
    module Users
      class Edit < Pages::Base
        include Partials::UserForm

        has_node :update_user_button, '//input[@value ="Update User"]', :xpath
      end
    end
  end

  # pages/user/new.rb
  require_relative '../base'
  module Pages
    module Users
      class New < Pages::Base
        include Partials::UserForm

        has_node :create_user_button, '//input[@value= "Create User"]', :xpath

      private

        def http_path
          new_user_path
        end
      end
    end
  end
{% endhighlight %}

# Крок #5
В цьому кроці ми:
1. Додамо можливість робити скріншот до page classes
2. Порівняємо як виглядав тест до Крок #1 та після Крок #5

Перша частина досить проста, оскільки ми вже маємо тест як об'єкт-collaborator
у  `Pages::Base` нам лише потрібно додати `take_screenshot` до списку методів які ми делегуємо,
всі зміни можна переглянути у [відповідному комміті][step-five]

Тепер давайте порівняємо що ми мали на початку і як тест виглядає після рефакторингу
#### До
{% highlight ruby %}
# test/system/users_test.rb
require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit users_url

    assert_selector "h1", text: "User"
  end

  test 'creating new user' do
    visit users_url
    click_on 'New User'
    fill_in 'First name', with: 'Bill'
    fill_in 'Last name', with: 'Bird'
    click_on 'Create User'
    visit users_url
    assert_text 'Bill Bird'
  end

  test 'editing existing user' do
    User.new(first_name: 'Bill', last_name: 'Bird').save
    visit edit_user_url(User.first)
    fill_in 'First name', with: 'First'
    fill_in 'Last name', with: 'Last'
    click_on 'Update User'
    assert_text 'First Last'
  end
end
{% endhighlight %}
#### Після
{% highlight ruby %}
# test/system/users_test.rb
require 'application_system_test_case'
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'show')
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'new')
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'index')
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'users', 'edit')

class UsersTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit users_url

    assert_selector "h1", text: "User"
  end

  test 'creating new user' do
    ::Pages::Users::Index.new(test: self).instance_eval do
      visit
      new_user_link.click
      take_screenshot
    end

    ::Pages::Users::New.new.instance_eval do
      visit
      fill_out_user_form
      create_user_button.click
    end

    ::Pages::Users::Show.new(test: self, url: user_path(User.last)).instance_eval do
      check_main_elements_presence
      assert notice.text == 'User was successfully created.'
    end

    ::Pages::Users::Index.new.visit
    assert_text 'Bill Bird'
  end

  test 'editing existing user' do
    User.new(first_name: 'Bill', last_name: 'Bird').save

    ::Pages::Users::Edit.new(url: edit_user_url(User.first)).instance_eval do
      visit
      fill_out_user_form(first: 'First', last: 'Last')
      update_user_button.click
    end

    ::Pages::Users::Index.new(test: self).instance_eval do
      visit
      assert_text 'First Last'
    end
  end
end
{% endhighlight %}
версія 'Після' має певні переваги, ми перерахуємо їх у підсумку

# Підсумок

Переваги OO підходу:
1. Тести менш 'крихкі' - якщо структура чи логіка сторінки зміниться досить буде змінити лише page class
2. Тести більш зрозумілі - завдяки використанню `instance_eval` та блоків завжди зрозуміло на якій сторінці ви знаходитесь
3. Значно простіше описати структуру сторінки
4. Однаковий функціонал можна помістити в модуль
5. Інші члени команди можуть використовувати готові page classes
6. Pages classes є POROs, Ви можете використовувати всю красу/потужність Ruby в них

Код:
* [Проект][application]
* [Крок #1][step-one]
* [Крок #2][step-two]
* [Крок #3][step-three]
* [Крок #4][step-four]
* [Крок #5][step-five]


# Для роздумів:
1. Мені не подобається що `Pages::Base` має `include Rails.application.routes.url_helpers`.  Це було зроблено лише щоб показати що статичний URL може бути частиною page class, має бути кращий спосіб
2. `has_node` працює лише з одним елементом, варто додати `has_nodes` для колекцій
3. В залежності від використаного фреймворку, методи делеговані в `Pages::Base` відрізнятимуться, проте його можна використовувати з іншими фреймворками (RSpec, ...)
5. Замість багатьох тестів можна мати один супер-тест, тоді не доведеться чистити базу даних, можна групувати частини тесту за роллю користувача. Додаткові дані в базі можуть допомогти знайти глюки або лише ускладнити Ваше життя =)

[application]: https://github.com/bpohoriletz/bpohoriletz.github.io/tree/master/samples/oop_and_system_tests
[step-one]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/3803a56838360529898c6522d44c6cecccec2a20#diff-25437258f2fe39fc774476f923daa186
[step-two]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/0bb7eee0d824007b7719893b1bdc2a4913f9ff78#diff-25437258f2fe39fc774476f923daa186
[step-three]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/255e1f0c96a20ac570f8049720663c66a78bcfc6#diff-25437258f2fe39fc774476f923daa186
[step-four]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/1efd516747c9ddac87024e38867b4f984ed2ed05#diff-25437258f2fe39fc774476f923daa186
[step-five]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/470815de082bbb57a23bdbfaaccb15af3b95374f#diff-25437258f2fe39fc774476f923daa186
[node-element]: http://www.rubydoc.info/github/jnicklas/capybara/Capybara/Node/Element
[node-element-first]: http://www.rubydoc.info/github/jnicklas/capybara/Capybara%2FNode%2FFinders:first
