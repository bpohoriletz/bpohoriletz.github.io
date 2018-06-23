---
layout: post
post_title: OOP and System Tests in Ruby on Rails
---
* Time: 30-40 min
* Level: Intermediate/Advanced
* Code: [GitHub][application]

In this post we will take a look at a way to improve sample `Rails 5.1.3 System Test` using POROs, collaborators, delegation and modules.

# STEP #0
Basic system test, before refactoring
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
it verifies three things:
1. If we can visit the index page and if it has the structure we expect
2. If we can create a new user and see it on the index user page
3. If we can update user information and see the changes on the index
   user page

# Step #1
In this step we'll:
1. Introduce an abstract clas that will help us describe page structure
and functionality
2. Add a page class to test show user page
3. Use new page class in a test

As a first step let's introduce an abstract class with a single method that
will help us specify what elements we have on the page, actions from
this step can be found in the [corresponding commit][step-one]
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
Let's take a closer look at `initilaize` method and instance variables
there:
* `@current_session` - defaults to `Capybara.current_session`,
collaboratior object that allows us use driver inside `has_node` method
* `@url` - requidred parameter, URL of the page under test
* `@css_wrapper` - defaults to an empty string, helpful when all elements
under test are within an element with particular CSS class

Now let's introduse a new class that describes a show user page
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
You can see here three ways to identify an element on the page:
1. By CSS id
2. By type and text
3. By xpath

Things to remember:
* `has_node` is only a wrapper around
[Capybara::Node::Finders#first][node-element-first] so same thing may be
done in a few ways
* `has_node` result is equal to [Capybara::Node::Finders#first][node-element-first], if the element is found it's result is an
instance of [Capybara::Node::Element][node-element]


Now let's use `Pages::Users::Show` in the test for `UsersController#show`
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
this is a small first step to understand better how to use page classes

# Step #2
In this step we will:
1. Introuduce a new `Pages::Base#visit` method
2. Include `Rails.application.routes.url_helpers` in `Pages::Base` in
   order to have access to the routes inside the class
3. Add `Pages::Users::New`, `Pages::Users::Edit`, `Pages::Users::Index`
classes
4. Use new classes to refactor our sample test

I won't include code for new pages here you can find it in the [corresponding commit][step-two]. Let's take a look at how the test looks now instead:
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
We have three more steps left, but let's take a look what we've acheived
already:
1. Now we use class methods instead of raw selectors so if page
structure change we will have to change only the corresponding class
2. Because we use collaborator objects we have nice blocks and it's
   clear on what page we are an every line

# Step #3
In this step we will:
1. Add ability to verify if the element is present in page classes
2. Add a method to `Pages::Users::Show` to verify page structure

Let's take a look at the changes in the test first ([corresponding commit][step-three])

#### Before
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

#### After
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

`Pages::Users::Show#check_main_elements_presence` definition
{% highlight ruby %}
  # test/support/pages/users/show.rb
  def check_main_elements_presence
    notice_present?
    edit_user_link_present?
    back_link_present?
  end
{% endhighlight %}
In order to do this step we:
1. Changed the `Pages::Base#initialize` to accept new collaborator
object `test:`
2. Changed the `Pages::Base#has_node` to define both accessor and
`*_present?` methods

# Step #4
In this step we will extract functionality into a module ([corresponding_commit][step-four])

Let's first compare `Pages::User::Edit` and `Pages::User::New`
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
they both have two same nodes `first_name` and `last_name`, which isn't
strange - we render same partial `form` on both pages. Except for that
when testing these pages we fill out this form, let's extract these two
pieces to a module.

#### `Pages::Users::Partials::UserForm` module
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
#### Pages after refactoring
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

# Step #5
In This step we will:
1. Add ability to take screenshots to the page classes
2. Compare test we had before Step #1 and after Step #5

First item is quite stratightforward, since we already have a test as a
collaborator in `Pages::Base` we only need to add `take_screenshot` to a
list of methods we delegate, you can find changes in the
[corresponding commit][step-five]

Now let's compare what we had in the beginning
#### Before
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
and how the test looks now
#### After
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
after version has few advantages, they will be listed in a summary
section

# Summary

Advantages of the OO approarch:
1. Tests are less brittle - if page structure/logic changes you will
need to change only corresponding page class
2. Tests are more readable - because of `instance_eval` blocks you
always know which page are you on
3. It's much easier to define elements that exist on the page
4. Same functionality can be extracted
5. Other team mebers may use page classes in their tests
6. Pages are POROs, all the beauty/power of Ruby can be used there

Code:
* [Apllication][application]
* [Step #1][step-one]
* [Step #2][step-two]
* [Step #3][step-three]
* [Step #4][step-four]
* [Step #5][step-five]


# Food for thought
1. I'm not happy with the fact that `Pages::Base` has `include Rails.application.routes.url_helpers`. This is done only to show that
if the page URL is static it can become a part of the page class, there
should be a better way to acheive it
2. `has_node` works only for a single element, would be cool to have `has_nodes` for collections. Once again page classes are POROs so
thay may and should be changed to fit your needs
3. Folder with page classes may be a part of autoload paths, but not
   everyone likes autoloading
4. Depending on a test framework delegated methods in `Pages::Base` will differ, but it can be used with other test frameworks (like RSpec) too
5. Instead of having multiple test there could be one test, you won't
   truncate database, you may have tests grouped by the user that is
   logged in, additional data in the database may help you discover bugs
   or make your hate your life :)

[application]: https://github.com/bpohoriletz/bpohoriletz.github.io/tree/master/samples/oop_and_system_tests
[step-one]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/3803a56838360529898c6522d44c6cecccec2a20#diff-25437258f2fe39fc774476f923daa186
[step-two]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/0bb7eee0d824007b7719893b1bdc2a4913f9ff78#diff-25437258f2fe39fc774476f923daa186
[step-three]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/255e1f0c96a20ac570f8049720663c66a78bcfc6#diff-25437258f2fe39fc774476f923daa186
[step-four]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/1efd516747c9ddac87024e38867b4f984ed2ed05#diff-25437258f2fe39fc774476f923daa186
[step-five]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/470815de082bbb57a23bdbfaaccb15af3b95374f#diff-25437258f2fe39fc774476f923daa186
[node-element]: http://www.rubydoc.info/github/jnicklas/capybara/Capybara/Node/Element
[node-element-first]: http://www.rubydoc.info/github/jnicklas/capybara/Capybara%2FNode%2FFinders:first
