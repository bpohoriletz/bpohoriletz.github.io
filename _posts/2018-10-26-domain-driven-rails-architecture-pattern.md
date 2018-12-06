---
layout: post
post_title: '[EN] Domain Driven Rails Architecture'
title: '[EN] Domain Driven Rails Architecture'
description: 'The following article will describe an architecture of a Rails
application that is a combination of ideas from DDD and referenced articles
as well as a few additional tools to monitor the quality of the code.'
lang: 'enUS'
---
* Time: 30-40 min
* Level: Intermediate/Advanced
* Code: [GitHub][application]
* References:
  * [The Modular Monolith: Rails Architecture – Dan Manges][mm_reference]{:target='_blank_'}
  * [Counterintuitive Rails - Ivan Nemytchenko][cir_reference]{:target='_blank_'}
  * [Rails Parts – Tom Rothe][rp_reference]{:target='_blank_'}
  * [Scaling Teams using Tests for Productivity and Education - Julian Nadeau][st_reference]{:target='_blank_'}

The following article will describe an architecture of a Rails
application that is a combination of ideas from the referenced articles
as well as a few additional tools to monitor the quality of the code.
Main requirements for the application are:
  1. Separation of view(representation) and business logic(your
  domain)
  2. Separation of dependencies(gems) and as a result ability to run unit
  tests in isolation
  3. Solution has to be simple and straightforward (Rails is awesome and
  we're not going to fight with it)

TLDR - [Github repo][application] and a [commit][commit] with all the
changes applied to a fresh Rails application

# **Separation of representation and domain** #
The first thing to do is to have clear separation of representation and
business logic in the folder structure (and in your head). In order to
achieve this we will introduce a new folder called `representations` and
put everything we need to represent domain entities there. In the
example those were:
  - `representations/`
    - `assets/`
    - `controllers/`
    - `decorators/`
    - `public/`
    - `views/`
    - `vendor/`
    - `routes.rb`

> I personally prefer using decorators instead of helpers so there is no
`helpers/` folder.

Next we will setup a folder structure for your domain  entities and
logic - none of those two should be a part of a representation layer. In
order to do so let's create a new folder `domain/` and move our models
and database configuration there:
  - `domain/`
    - `contexts/`
    - `database.yml`

The name `contexts/` here is a reference to [Bounded
Context][bc_reference] pattern in a DDD theory, you may name it
differently and have any folder structure within it.

Now we need to make Rails aware of a change in a folder structure. This
is done in the `config/application.rb` using
[Rails::Application][rap_reference]

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
After this change Rails will work with new layout as if the original one
was never changed - autoloading, eager loading, testing, asset compilation - all
are fully functional.

> I personally believe that having `ApplicationController` and
> `ApplicationRecord` as `Concerns` improves flexibility of the code, so in
> the provided example they are concerns and there is an additional
> `config/initializers/draper.rb` file to make Draper work
{% highlight ruby %}
 # config/initializers/draper.rb

 3 DraperBaseController = Class.new( ActionController::Base )
 4 DraperBaseController.include( ApplicationController )
 5
 6 Draper.configure do |config|
 7   config.default_controller = DraperBaseController
 8 end
{% endhighlight %}

# **Separation of environments and building independent test suites** #

Since we've separated the representation and domain having separate test
suite for each would be beneficial - properly implemented those suites would
be faster, isolated and independent. Let's prepare environments for them
first:
  1. Introduce separate `Gemfile` and `Gemfile.lock` for representations
  and domain
  2. Make main `Gemfile` use ones we add on the previous step
  3. Setup independent test environments for `representations/` and `domain/`

Adding more `Gemfiles` is trivial - just create new file and extract
dependencies from the main `Gemfile`.

Make main `Gemfile` aware of additional dependencies is quite simple too  -
`bundler` already has a method to load additional files, `bundler` will
complain if there are any issues as if the `Gemfile` has never been split.

{% highlight ruby %}
 # Gemfile

 54 %w[ representations/Gemfile domain/Gemfile ].each do |custom_gemfile|
 55   eval_gemfile custom_gemfile
 56 end
{% endhighlight %}

Setting up context specific test suites is the hardest part (and most
likely it will introduce more issues as application grows). As a first
step we run `rspec --init` within `representations/` and `domain/`, as a
result  new `representations/spec` and `doman/spec` folders will be
created.

`spec/spec_helper.rb` file will be added automatically too, but
`spec/rails_helper.rb` won't and we have to add and configure it manually.

#### Domain test suite configuration ####
To start with we will copy the `spec/rails_helper.rb` to the
`domain/spec/rails_helper.rb` and delete everything before `RSpec.configure do |config|`.
This is done in order to not load any dependencies (we will load
everything we need later). We won't be able to run tests at this point,
but that's only a first step

Next we actually make sure we load only things we actually need:

- load `active_record` and `rspec-rails`
{% highlight ruby %}
  # domain/spec/rails_helper.rb

  3 require 'active_record/railtie'
  4 require 'active_support'
  5 require 'rspec/rails'
{% endhighlight %}
- load test suite dependencies
{% highlight ruby %}
  7 ENV['RAILS_ENV'] ||= 'test'
  8 require 'spec_helper'
  9 require 'database_cleaner'
 10 require 'factory_bot'
 11 require 'pry-byebug'
{% endhighlight %}
- create an Application for `rspec-rails` to work (the most fragile
piece unfortunately)
{% highlight ruby %}
 13 ContextsTestApplication = Class.new( ::Rails::Application )
 14 ::Rails.application = ContextsTestApplication.new
{% endhighlight %}
- connect to a database
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
- load domain (shared concerns first since there is no autoloading
mechanism)
{% highlight ruby %}
 24 %w[ concerns contexts ].each do |folder|
 25   Dir[ File.expand_path( "../#{folder}/**/*.rb", __dir__ ) ].each { |f| require f }
 26 end
{% endhighlight %}
- load initializer/support files
{% highlight ruby %}
 28 Dir[ './spec/support/*.rb' ].each { |f| require f }
 29
 30 RSpec.configure do |config|
{% endhighlight %}

#### Representations test suite configuration ####

Setting up the test suite for representations is quite similar, the only
difference is things we load:

- load `action_controller` and `rspec-rails`
{% highlight ruby %}
  # representations/spec/rails_helper.rb
  3 require 'action_controller/railtie'
  4 require 'active_support'
  5 require 'rspec/rails'
  6 require 'spec_helper'
{% endhighlight %}
-  create an Application for `rspec-rails` and load routes
{% highlight ruby %}
  8 RepresentationsTestApplication = Class.new( ::Rails::Application )
  9 ::Rails.application = RepresentationsTestApplication.new
 10 require_relative '../routes'
{% endhighlight %}
- load dependencies
{% highlight ruby %}
 12 require 'pry-byebug'
 13 require 'uuid'
{% endhighlight %}
- load representation code (shared concerns first since there is no autoloading
mechanism)
{% highlight ruby %}
 15 %w[ concerns controllers decorators ].each do |folder|
 16   Dir[ File.expand_path( "../#{folder}/**/*.rb", __dir__ ) ].each { |f| require f }
 17 end
{% endhighlight %}

Now we have two independent test suites that:
 - may include only unit tests
 - force you to stay within your context
 - load/reload environment fast (files took 2.65 seconds to load if run from
 main app and only 0.96642 seconds to load if run independently)

> Since test suite files are within `representations/` and `domain/` folders
> they  can't  be within the `app/` folder - Rails will try to eager load
> all files in those folders in production


# **Final parts** #
As I've mentioned in my [previous][mon_reference] post, I believe that
tests within top level `spec/` and `test/` folders should not be unit
tests and always test multiple components of the application. Opposite
applies to tests within `repreentations/spec` and `domain/spec` - those
always should be unit tests.

One issue with this setup is that in order to be able to execute tests
within context-specific environment you have to have separate
`Gemfile.lock` files, which may result in different gem versions used
when you run tests in isolation and as a whole suite. Let's introduce a
test to make sure we get a notification if such situation happens.

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

The example [application][application] also includes Git hooks that will
be installed into your application if you run `./bin/setup` and will be
automatically executed before and after you commit.

Before hook runs Rubocop against changes staged for commit, after hook
allows you to run rails_best_practices, reek, brakeman and mutant
against your code

# **Summary** #

I like a lot the flexibility that this architecture provides - if needed
you can isolate any part of your code and threat it as a standalone
unit. At the same time it uses Rails API, so it's not against it -
rather it's a yet another way to organize your code.
I'm eager to try it with more complex and legacy applications -
introducing new architecture is quite simple in both cases.

Links:
 * [Application][application]
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
