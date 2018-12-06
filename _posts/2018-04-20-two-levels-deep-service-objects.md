---
layout: post
post_title: '[EN] Two levels deep Service Objects in Ruby'
title: '[EN] Two levels deep Service Objects in Ruby'
description: 'Make your Service Objects tell the good story right away, the very first time you see them'
lang: 'enUS'
---
* Time: 20-30 min
* Level: Beginner/Intermediate
* Code: [GitHub][application]{:target='_blank_'}

Before I started writing this post I searched for other people looking at code
code from this perspective - found one [How deep is your code?][other]{:target='_blank_'}

I needed an example of complicated Service Object and
found it in one of the Discourse source [files][example]{:target='_blank_'}. I'm not criticizing
this code by any mean and there is a great example of what I'm going
to try to achieve in the same [repository][good_example]{:target='_blank_'}

I personally prefer small classes, short, single purpose methods over
the one big piece of code. Having said that I have to admit that this approach
has a significant downside - methods are short quite often
because internally they call other methods, which call other methods,
which call other methods... So you have to go down the rabbit hole
before you figure out what method actually does, sometimes you loose the
big picture in the meantime.

I don't want to do this, I don't want to look at 5-10 private methods to figure
out what are the implications of calling a public method, I want public
method to be able to tell me the story right away, the very first time I
see it - maybe there is a way?

Once I saw a complexity metric described by Sandi Metz in her talk [All the Little Things][talk]{:target='_blank_'} - the Squint Test.
While this metric was used to measure the complexity of the nested conditionals, we
could think about calling methods in a similar way. If a method calls other
method let's indent it as if it was a nested if:
{% highlight ruby %}
def parent
  child_level_two
  # some code
end

def child_level_two
  # some code
  child_level_three
end

def child_level_three
  # some code
  child_level_four
  # some code
end
{% endhighlight %}
now let's write down all involved methods and indent each nested call
{% highlight ruby %}
def parent
  child_level_two
    child_level_three
  child_level_two
    child_level_three
    child_level_three
  child_level_two
  child_level_two
    child_level_three
    child_level_three
      child_level_four
  child_level_two
  child_level_two
    child_level_three
      child_level_four
      child_level_four
end
{% endhighlight %}
we got similar figure with changes in shape, the bigger is the shape
change - the more nesting we have.

# STEP #1
Code changes in this step can be found in the [corresponding commit][step-one]

Service object before refactoring, I've extracted external dependencies
into `dependencies.rb` and added placeholders for required methods

{% highlight ruby %}
# user_updater.rb
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/time/calculations'
require 'active_model'

require_relative 'dependencies'

class UserUpdater
  delegate :change_post_owner, to: :guardian

  def update(attributes = {})
    save_options = false
    saved = nil
    old_user_name = user.name.present? ? user.name : ""

    user_profile = user.user_profile
    user_profile.location = attributes.fetch(:location) { user_profile.location }
    user_profile.dismissed_banner_key = attributes[:dismissed_banner_key] if attributes[:dismissed_banner_key].present?
    user_profile.website = format_url(attributes.fetch(:website) { user_profile.website })
    user_profile.profile_background = attributes.fetch(:profile_background) { user_profile.profile_background }
    user_profile.card_background = attributes.fetch(:card_background) { user_profile.card_background }
    if SiteSetting.enable_sso && !SiteSetting.sso_overrides_bio
      user_profile.bio_raw = attributes.fetch(:bio_raw) { user_profile.bio_raw }
    end

    user.name = attributes.fetch(:name) { user.name }
    user.locale = attributes.fetch(:locale) { user.locale }
    user.date_of_birth = attributes.fetch(:date_of_birth) { user.date_of_birth }
    if can_grant_title?(user)
      user.title = attributes.fetch(:title) { user.title }
    end

    # special handling for theme_key cause we need to bump a sequence number
    if attributes.key?(:theme_key) && user.user_option.theme_key != attributes[:theme_key]
      user.user_option.theme_key_seq += 1
    end

    OPTION_ATTR.each do |attribute|
      if attributes.key?(attribute)
        save_options = true

        if [true, false].include?(user.user_option.send(attribute))
          val = attributes[attribute].to_s == 'true'
          user.user_option.send("#{attribute}=", val)
        else
          user.user_option.send("#{attribute}=", attributes[attribute])
        end
      end
    end

    # automatically disable digests when mailing_list_mode is enabled
    user.user_option.email_digests = false if user.user_option.mailing_list_mode

    fields = attributes[:custom_fields]
    if fields.present?
      user.custom_fields = user.custom_fields.merge(fields)
    end

    User.transaction do
      if user.user_option.save && user_profile.save && user.save
        StaffActionLogger.new(@actor).log_name_change(
          user.id,
          old_user_name,
          attributes.fetch(:name) { '' }
        )

        saved = true
      end
    end

    saved
  end

  private

  attr_reader :user, :guardian

  def initialize(actor, user, guardian = Guardian.new(actor))
    @user = user
    @guardian = guardian
    @actor = actor
  end

  def format_url(website)
    return nil if website.blank?
    website =~ /^http/ ? website : "http://#{website}"
  end
end
{% endhighlight %}

# STEP #2
This step was divided into few smaller chunks:
- #2.1 Refactor `UserUpdater#update` method ([commit][step-2.1])
- #2.2 Refactor methods that were extracted in 2.1
  - #2.2.1 Refactor `UserUpdater#update_user_profile` method  ([commit][step-2.2.1])
  - #2.2.2 Refactor `UserUpdater#update_user` method ([commit][step-2.2.2])
  - #2.2.3 Refactor `UserUpdater#update_user_option` method ([commit][step-2.2.3])
  - #2.2.4 Refactor `UserUpdater#save_user_data` method ([commit][step-2.2.4])

I'll skip details here because those are quite straightforward extractions, they were done to simplify
`UserUpdater#update` method, make it small and easy to understand.
{% highlight ruby %}
# user_updater.rb
class UserUpdater
  delegate :change_post_owner, to: :guardian

  def update(attributes = {})
    old_user_name = user.name.present? ? user.name : ""

    update_user_profile( user.user_profile, attributes )
    update_user( user, attributes )
    update_user_option( user.user_option, attributes )
    save_user_data(user, old_user_name, attributes)
  end

  private
  # ...
{% endhighlight %}

However I believe that too much information was hidden with this
extraction. From the method definition we no longer see that:
1. There is a transaction
2. Some parts are updated only if particular conditions are met
3. We use constant to determine what to update
4. It's not obvious that we return (and depend on the returned value
   somewhere) `true`/`false` depending on the
   result of the transaction

In addition to hiding information, I strongly dislike how new
`UserUpdater#update_user_profile` method looks - it's a private method that
consists of only other private methods, and once again - no conditionals
inside

{% highlight ruby %}
# user_updater.rb
def update_user_profile( user_profile, attributes )
  update_geo_data( user_profile, attributes )
  update_web_data( user_profile, attributes )
  update_background_data( user_profile, attributes )
  update_bio_raw( user_profile, attributes )
end
{% endhighlight %}

I believe that methods like this only  introduce additional level of
complexity and have no right to exist

# STEP #3
Code changes in this step can be found in the [corresponding commit][step-3]{:target='_blank_'}

In this step we drop private methods that were (almost) only wrappers
around other private methods and change remaining method names to
reflect the intention better
{% highlight ruby %}
# user_updater.rb
class UserUpdater
  delegate :change_post_owner, to: :guardian
  delegate :log_user_name_change, to: :StaffActionLogger

  def update(attributes = {})
    old_user_name = user.name.present? ? user.name : ""
    user_profile = user.user_profile
    user_option = user.user_option

    set_user_profile_geo_data( user_profile, attributes )
    set_user_profile_web_data( user_profile, attributes )
    set_user_profile_background_data( user_profile, attributes )
    set_user_profile_bio_raw( user_profile, attributes )

    set_user_bio(user, attributes, update_title: can_grant_title?(user) )
    user.custom_fields = user.custom_fields.merge( attributes.fetch( :custom_fields, {} ) )

    set_user_option_theme_key(user_option, attributes)
    OPTION_ATTR.each { |attribute| set_user_option_single_attribute(user_option, attributes, attribute) }
    # automatically disable digests when mailing_list_mode is enabled
    user_option.email_digests = false if user_option.mailing_list_mode

    return false unless User.transaction { user.user_option.save && user.user_profile.save && user.save }
    log_user_name_change( user.id, old_user_name, attributes.fetch(:name) { '' } )

    return true
  end
{% endhighlight %}

the `UserUpdater#update` has become almost three times bigger compared to
the previous version however it now also tells us a better story.

It's not perfect (and will never be) but we will make one more step to
improve it and compare with the shorter version from Step #2 afterwards.

# STEP #4
Code changes in this step can be found in the [corresponding commit][step-4]{:target='_blank_'}

In this step we will do final polishing and compare results

{% highlight ruby %}
# user_updater.rb

# Short version
class UserUpdater
  # ...
  def update(attributes = {})
    old_user_name = user.name.present? ? user.name : ""

    update_user_profile( user.user_profile, attributes )
    update_user( user, attributes )
    update_user_option( user.user_option, attributes )
    save_user_data(user, old_user_name, attributes)
  end
# Two levels deep version
class UserUpdater
  # ...
  def update(attributes = {})
    @attributes = attributes
    old_user_name = user.name.present? ? user.name : ""

    set_user_profile_geo_data
    set_user_profile_web_data
    set_user_profile_background_data
    set_user_profile_bio_raw if should_update_user_profile_bio_raw?

    set_user_bio( update_title: can_grant_title?(user) )
    user.custom_fields = user.custom_fields.merge( attributes.fetch( :custom_fields, {} ) )

    set_user_option_theme_key if should_update_user_option_theme_key?
    OPTION_ATTR.each do |attribute|
      set_user_option_single_attribute( attribute )
    end
    # automatically disable digests when mailing_list_mode is enabled
    user_option.email_digests = false if user_option.mailing_list_mode

    return false unless User.transaction { save_user_and_related_entities }
    log_user_name_change( user.id, old_user_name, attributes.fetch(:name) { '' } )

    return true
  end
{% endhighlight %}

I believe longer version has the following benefits:
1. Code tells great story with lots of implementation details
2. It follows Open/Closed principle
3. You're always at most one step away from the full private method
   definition

# Summary
In order to be two levels deep code has to follow the following rules:
1. Public methods can't call other public methods of the same class
2. Private/protected methods can't call other private/protected methods

I have two more rules of thumb
1. Avoid conditionals in private methods
2. Conditionals have to reflect on private methods rather than on boolean
   expressions

Code:
* [Repository][application]
* [Step #1][step-one]
* [Step #2.1][step-2.1]
* [Step #2.2.1][step-2.2.1]
* [Step #2.2.2][step-2.2.2]
* [Step #2.2.3][step-2.2.3]
* [Step #2.2.4][step-2.2.4]
* [Step #3][step-3]
* [Step #4][step-4]

# Food for thought
1. These rules are quite easy to follow in Service Objects because
   usually they describe some process/algorithm - where else they can be
applied?
2. How about delegated methods, can we threat them as private when measuring?
3. How about accessor methods, can we threat them as private when measuring?

[application]: https://github.com/bpohoriletz/bpohoriletz.github.io/tree/master/samples/two_level_deep_service_objects
[talk]: https://www.youtube.com/watch?v=8bZh5LMaSmE&t=1892s&index=3&list=PLqwEgoaqsYziFoM8UN2GmWc0BySnWUozK
[other]: http://edmundkirwan.com/general/tuples.html
[example]: https://github.com/discourse/discourse/blob/482c615ef882c1953070125e0a813683f979e5ff/app/services/user_updater.rb
[good_example]: https://github.com/discourse/discourse/blob/482c615ef882c1953070125e0a813683f979e5ff/app/services/user_merger.rb
[step-one]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/a8bf6246520d6ee45db7b1aa708056fa1821de25
[step-2.1]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/60a6e89f7be50eb4b143d6aefa0357e0899e04ae
[step-2.2.1]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/4c383dd20b20addc34b20e6cfa7dc953aac5ad90
[step-2.2.2]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/d362cdad5cd45c2319fcba961ef92ea85673589f
[step-2.2.3]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/618215dd0d8183c76ebf7549fa8eb9771523bb19
[step-2.2.4]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/3f3fb36a5d502bcb570f4aa150faf2bcee073bba
[step-3]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/252e123e81951e4a72c7d08dbcbedfbba032a71c
[step-4]: https://github.com/bpohoriletz/bpohoriletz.github.io/commit/56690ffe09c4d832feb346456ca00826d8517bd6
