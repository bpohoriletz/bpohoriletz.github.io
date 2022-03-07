---
layout: post
post_title: '[EN] Rails 7 application inside Docker on macOS: Part one - container'
title: '[EN] Rails 7 application inside Docker on macOS: Part one - container'
description: 'How to create Rails 7 app with all dependencies hidden inside a
Docker container'
lang: 'enUS'
---
* Time: 5-10 min
* Level: Beginner
* Code: [Application][appl]{:target='_blank_'}
* Version: Mar 06, 22
* References:
  * [Graceful Dev – Avdi Grimm][avdi]{:target='_blank_'}
  * [Docker Docs][dock]{:target='_blank_'}
  * [Alpine, Slim, Stretch, Buster, Jessie, Bullseye — What are the Differences in Docker Images? - Julie Perilla Garcia][juli]{:target='_blank_'}

**Ukraine is at WAR with Russia now! World history being written these
days - become one who was involved! Your grandchildren would love to
hear the stories!**
- **[Join our IT Army][it_army]{:target='_blank_'}**
- **[Spread the word][spread_word]{:target='_blank_'}**

**Слава Україні! Glory to Ukraine!**

Sometimes we want to play with the new version of Ruby/Rails, but in
order to do so we need to install dependencies which quite often is not
so seamless. So let's take a look how to use Docker and shell commands in
order to quickly start new project with any combination of Ruby/Rails
version and keep the macOS itself clean as a baby's bottom.

#### TL;DR - [Gist][gist]{:target='_blank_'}

# Process step-by-step

The overall process is quite straightforward and consists of seven dependent steps

1. [Create a folder for a project on local drive](#step-1---create-a-folder-for-a-project-on-local-drive)
2. [Create `Gemfile` with ruby/rails version within this folder](#step-2---create-gemfile-with-rubyrails-version-within-this-folder)
3. [Create configuration for Docker within this folder](#step-3---create-configuration-for-docker)
4. [Build a Docker image](#step-4---build-a-docker-image)
5. [Install rails non the new container](#step-5---install-rails-in-the-new-container)
6. [Create new rails project from Docker image with files stored on the
local drive](#step-6---create-new-rails-project)
7. [Start the server](#step-7---start-the-server)

Now let's take a look at each step in detail:

#### Step #1 - Create a folder for a project on local drive
````sh
export DOCKER_RAILS_VERSION="7.0.1"
export DOCKER_RUBY_VERSION="3.1.0"
mkdir app
cd app
````
the folder will be named `/app` and all new files will be added inside

#### Step #2 - Create `Gemfile` with ruby/rails version within this folder
````sh
echo "ruby '$DOCKER_RUBY_VERSION'
source 'https://rubygems.org'
gem 'rails', '$DOCKER_RAILS_VERSION'" > Gemfile
````
this step is done only for the convenience - we will use bundler
later to install correct version of the rails gem

#### Step #3 - Create configuration for Docker

First we create folder where configuration files will live
````sh
mkdir .devcontainer
cd .devcontainer
````
next we add `Dockerfile` that will be used later by Docker Compose to
build our image
````sh
echo "FROM ruby:$DOCKER_RUBY_VERSION-slim
RUN apt-get update \
 && apt-get install -y make gcc git sqlite3 libsqlite3-dev \
 && rm -rf /var/lib/apt/lists/*" > Dockerfile
````
we add `gcc`, `git`, `sqlite3`, `libsqlite3-dev` packages in order to
be able to compile gems later

> I'm using slim version of the ruby image from Docker, you can read more
> about the difference between images in [Alpine, Slim, Stretch, Buster, Jessie, Bullseye — What are the Differences in Docker Images?][juli]{:target='_blank_'} by Julie Perilla Garcia

Now let's take a closer look at different pieces of `docker-compose.yml`
````sh
...
services:
  web:
...
````
this is the beginning of our service, it will be named `web`

````sh
...
    build:
      context: .
      dockerfile: Dockerfile
...
````
this section will tell the Docker Compose to use the `Dockerfile` within
`app/.devcontainer/` to build an image

````sh
...
    volumes:
      - "$(pwd)/..":/web:cached
    working_dir: /web
...
````
we will mount parent directory `app/` to the image as `/web` and set it
as a default directory for work, `:cached` part is added to improve the performance
of bind-mounted directories on macOS

````sh
...
    command: sleep infinity
...
````
this will keep the container running indefinitely

````sh
...
    environment:
      - BUNDLE_PATH=vendor/bundle
...
````
this is done in order to keep installed gems within the
`/app/vendor/bundle` folder and not install them every time we start the
container

````sh
...
    ports:
      - '3000:3000'" > docker-compose.yml
````
here we expose port from container 3000 to macOS

#### Step 4 - Build a Docker image
````sh
docker-compose up -d --build
````
this command will build an image and start the container, `-d` is for detached mode, `--build` to build image before starting container

#### Step 5 - Install rails in the new container
````sh
docker-compose exec web bundle
````
`web` is the name of the service where `bundle` command will be
executed, by default it will be run in the `web/` folder inside
container, that is `app/` folder on the macOS drive, where we created
`Gemfile` at [Step 2](#step-2---create-gemfile-with-rubyrails-version-within-this-folder)

#### Step 6 - Create new rails project
````sh
docker-compose exec web bundle exec rails new . -f
````
this will create new rails application inside `app/` folder and
overwrite existing `Gemfile`

#### Step 7 - Start the server
````sh
docker-compose exec web bundle exec rails s -b 0.0.0.0
````
you have to start the server at `0.0.0.0` in addition to the port exposing to make things work

Now if you navigate to [http://localhost:3000][loca]{:target='_blank_'}
you should see the default rails page

#### Extra
**Ukraine is at WAR with Russia now! World history being written these
days - become one who was involved! Your grandchildren would love to
hear the stories!**
- **[Join our IT Army][it_army]{:target='_blank_'}**
- **[Spread the word][spread_word]{:target='_blank_'}**

**Слава Україні! Glory to Ukraine!**
````sh
image: ruby-$DOCKER_RUBY_VERSION-rails-$DOCKER_RAILS_VERSION
````
this will add a tag to container with information on ruby/rails version

Don't forget to stop the container with `docker-compose down`

If `Gemfile` does not exist in the `web/` folder:
- stop all containers
- delete any built images
- restart Docker
- start from the [Step 1](#step-1---create-a-folder-for-a-project-on-local-drive)

#### Revisions
- Mar 06, 22
  - removed version from `Dockerfile`. Thanks to [Nick Janetakis][nickj]{:target='_blank_'}

[nickj]: https://www.reddit.com/user/nickjj_/
[appl]: https://github.com/bpohoriletz/bpohoriletz.github.io/tree/master/samples/rails-7-app-inside-docker-on-osx
[gist]: https://gist.github.com/bpohoriletz/9ba8c5a8eb92727ec24dccfe269f5ea8
[avdi]: https://graceful.dev/courses/tapastry/modules/2021/
[dock]: https://docs.docker.com/compose/compose-file/compose-file-v3/
[juli]: https://medium.com/swlh/alpine-slim-stretch-buster-jessie-bullseye-bookworm-what-are-the-differences-in-docker-62171ed4531d
[loca]: http://localhost:3000
[it_army]: https://t.me/itarmyofukraine2022
[spread_word]: https://www.pravda.com.ua/eng/
