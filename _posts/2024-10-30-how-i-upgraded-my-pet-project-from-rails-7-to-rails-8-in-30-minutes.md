---
layout: post
post_title: '[EN] How I upgraded my pet project from Rails 7 to Rails 8 in 30 minutes'
title: '[EN]  How I upgraded my pet project from Rails 7 to Rails 8 in 30 minutes'
description: 'Step by step Rails 7 to Rails 8 upgrade'
lang: 'enUS'
---
* Time: 10-15 min
* Level: Intermediate
* Code: [Application][appl]{:target='_blank_'}
* Revision: Oct 30, 24

#### **TL;DR** - I have a [`custom/`][custom]{:target='_blank_'} folder in my project where I keep files that I change instead of modifying generated files. The only change in generated files is customization loading. As a result when I need to upgrade a project I overwrite default files with `bin/rails new` and add a few `require "custom/file.rb"` statements.

Since Rails 8 will be released soon I decided to test my custom
application layout and upgrade prototype I use for my pet projects
from Rails 7 to Rails 8.
I will go over the whole process step by step and maybe customization
that made it easy will become one you'd like to try yourself.

The only feature application has is an authentication with devise
so I (almost) did not have any issues with app functionality or
changes introduced in Rails 8.

#### Section I - Updating project files to Rails 8
1. Change rails version in the `Gemfile`
````diff
- gem "rails", "~> 7.1.3", ">= 7.1.3.4"
+ gem "rails", "~> 8.0.0.rc1"
````
2. Delete `Gemfile.lock`
3. Uninstall all gems (`gem uninstall --all --force -x`)
4. Install bundler (`gem install bundler`)
5. Install rails (`bundle`)
6. Update project files (`rails new prototype -f -d postgresql -c tailwind`)
    * The command is one I used to generate project in the past. Depending
    on the situation, you could also use `bin/rails app:update --force`
7. [Commit][initial]{:target='_blank_'} everything

#### Section II - Bringing back customization

At this point I couldn't run the project because some files have been
overwriten with default versions provided by the generator. So next I reviewed
changes and put back customiztions.
Fortunately my project has just a few files that have changes and changes
are minimal.

*While reviewing I saw changes like*
````diff
- # Ignore all environment files (except templates).
+ # Ignore all environment files.
  /.env*
- !/.env*.erb
````
*and*
````diff
  # Throw-away build stage to reduce size of final image
- FROM base as build
+ FROM base AS build
````
*that made my inner perfectionista quite happy :) (also an indicator that people
do care)*

Overall I had to change eleven files:

> links don't open changes in each file unfortunately, so please use
> the file tree on the left

  * [.gitignore][gitignor]{:target='_blank_'}
  * [.rubocop.yml][rubocop]{:target='_blank_'}
  * [Gemfile][gemfile]{:target='_blank_'} (I have puma commented out on
  line 12 for AWS ElasticBenstalk compatibility)
  * [app/controllers/application_controller.rb][apcontr]{:target='_blank_'}
  * [app/views/layouts/application.html.erb][aplayou]{:target='_blank_'}
  * [config/application.rb][conappl]{:target='_blank_'}
  * [config/datbase.yml][condata]{:target='_blank_'}
  * [config/environments/development.rb][confdev]{:target='_blank_'}
  * [config/environments/production.rb][confprd]{:target='_blank_'}
  * [config/environments/test/rb][conftst]{:target='_blank_'}
  * [custom/config/routes.rb][curoute]{:target='_blank_'}

These changes introduced new gems so I had to run `bundle` once more to
install them.

That's all - I was able to start the server and saw the sign in UI.

#### Section III - Few final touches

One last part was to check if Rubocop checks and RSpec suite pass. I run
`bin/rubocop -A .` to fix the first one and had to
[change][tests]{:target='_blank_'} the test I have to make it pass.

#### Section IV - Custom project layout

**Problem:** Changes to generated project files interfere wit use of
`bin/rails new yourprojectname` as an upgrade mechanism.

**Idea:** Changes to generated files have to be minimal in order to put
them beck easily.

**Implementation:** Have separate files with changes and load them in
generated files.

In order to achieve the desired outcome (simple upgrade process) four
mechanisms are used:
* `require "../file.rb"` - pain ruby
* `eval_gemfile "../Gemfile"` - provided by the bundler gem
* `paths["file.rb"] =` - provided by Rails
* `initializer "name", after: :callback do` - provided by Rails
* `inherit_from: filename` - provided by rubocop gem

Whenever there is a need to change the generated file I
[introduce][extrrub]{:target='_blank__'} new file where I add the change
and load a file with change from the original file. Naming convention I
use - customization file has the same name as the generated with
`custom/` prefix. So custom configuration for `.rubocop.yml` is in
`custom/.rubocop.yml` etc.

Part of the customization resides in
[`custom/config/application.rb`][appconf]{:target='_blank_'}
which is required in [`config/application.rb`][apconfo]{:target='_blank_'}
so these changes are preserved while project is upgraded and later
introduced again.

#### Summary

Separation of generated by default project files and customizations
made upgrade process much simpler for me. Since customization is done
with built-in tools it's quite simple to implement and having the
naming convention makes it easy to understand and follow.

#### Extra

While I was working on this post 8.0.0.rc2 was released and it took me just
a few minutes to upgrade the project.

#### Revisions
- Oct 30, 24 - Initial post

[appl]: https://github.com/bpohoriletz/prototype
[custom]: https://github.com/bpohoriletz/prototype/tree/841e500dc41327e188e08733d4b1108b9362a5ec/custom
[initial]: https://github.com/bpohoriletz/prototype/commit/d455dc72e232021bfe6095c5ff224f0ff5ef55c2
[gitignor]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-bc37d034bad564583790a46f19d807abfe519c5671395fd494d8cce506c42947
[rubocop]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-4f894049af3375c2bd4e608f546f8d4a0eed95464efcdea850993200db9fef5c
[gemfile]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-d09ea66f8227784ff4393d88a19836f321c915ae10031d16c93d67e6283ab55f
[apcontr]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-766c34fd6533171eaf54300c153f89d6002c35c02cfc9c5b219251f85180ad07
[aplayou]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-f43fe075643e681b2c01c2f853bb0c4299d135b47fcbd4da96890d521c49e3eb
[conappl]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-c1fd91cb1911a0512578b99f657554526f3e1421decdb9e908712beab57e10f9
[condata]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-5a674c769541a71f2471a45c0e9dde911b4455344e3131bddc5a363701ba6325
[confdev]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-d3c4b3f41072daa416f1920511e9b2e26caea8c5cec0a14cb9508589a4dafa47
[confprd]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-da60b4e96eff2b132991226d308949e23f4ef3aad45ad59edd09cbc32cc6251e
[conftst]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-77f322f5ab0c54b1f2793b339574333dc55889645d910a93ede0fd7aa13b217ao
[curoute]: https://github.com/bpohoriletz/prototype/commit/3b34b5c27f1fdcb004b78b28f3443c6318d5436f#diff-1768406df9d93967c262ce2d73ff34b3acd9645af8f9b22a190375c0ef12f1f9
[tests]: https://github.com/bpohoriletz/prototype/commit/70496489a07ca780c1f47e4b5b1a2789bfca6e31
[extrrub]: https://github.com/bpohoriletz/prototype/commit/350fe1a87bc8dde45b4d1764492b0346111a57e7
[appconf]: https://github.com/bpohoriletz/prototype/blob/350fe1a87bc8dde45b4d1764492b0346111a57e7/custom/config/application.rb#L11
[apconfo]: https://github.com/bpohoriletz/prototype/blob/350fe1a87bc8dde45b4d1764492b0346111a57e7/config/application.rb#L29
