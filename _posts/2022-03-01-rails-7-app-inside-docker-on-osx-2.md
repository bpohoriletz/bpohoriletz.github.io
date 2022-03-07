---
layout: post
post_title: '[EN] Rails 7 application inside Docker®  on macOS: Part two - database and Mutagen'
title: '[EN] Rails 7 application inside Docker®  on macOS: Part two - database and Mutagen'
description: 'How to create Rails 7 app with all dependencies hidden inside a
Docker®  container'
lang: 'enUS'
---
* Time: 5-10 min
* Level: Beginner
* Code: [Application][appl]{:target='_blank_'}
* Revision: Mar 7, 22
* References:
  * [Part one][part_one]{:target='_blank_'}
  * [Mutagen Compose example][mutagen_compose]{:target='_blank_'}
  * [Docker®  on Mac - how to speed it up?][mutagen]{:target='_blank_'}

In this part we will add PostgreSQL databases for develpment and test
environments and use Mutagen to speed things up

**Ukraine is at WAR with Russia now! World history being written these
days - become one who was involved! Your grandchildren would love to
hear the stories!**
- **[Join our IT Army][it_army]{:target='_blank_'}**
- **[Spread the word][spread_word]{:target='_blank_'}**

**Слава Україні! Glory to Ukraine!**

#### TL;DR - [Gist][gist]{:target='_blank_'}

# Process step-by-step

The overall process is quite straightforward and consists of seven dependent steps

1. [Switch from SQLite to PostgreSQL and use Mutagen Compose](#step-1---switch-from-sqlite-to-postgresql-and-use-mutagen-compose)
2. [Add test and development databases](#step-2---add-test-and-development-databases)
3. [Add mutagen](#step-3---add-mutagen)

Now let's take a look at each step in detail:

#### Step #1 - Switch from SQLite to PostgreSQL and use Mutagen Compose
First let's add required packages for pg gem:
````diff
- 18. && apt-get install -y make gcc git sqlite3 libsqlite3-dev \
+ 18. && apt-get install -y make gcc git build-essential libpq-dev \
````
let's switch from `docker-compose` to `mutagen-compose` (more on
`mutagen-compose` later):
```diff
- 43. docker-compose up -d --build
+ 43. mutagen-compose up -d --build
44. # install rails
- 45. docker-compose exec web bundle
+ 45. mutagen-compose exec web bundle
46. # generate new rails project
- 47. docker-compose exec web bundle exec rails new . -f
+ 47. mutagen-compose exec web bundle exec rails new . -f --database=postgresql
48. # start rails server at IP 0.0.0.0 so that it's available on the host macOS
- 49. docker-compose exec web bundle exec rails s -b 0.0.0.0
+ 49. mutagen-compose exec web bundle exec rails s -b 0.0.0.0
```
also on line 47 we pass `--database=postgresql` flag to build new app
with PostgreSQL not SQLite

#### Step #2 - Add test and development databases
First add two services for development and test databases in
`docker-compose.yml`:
```sh
  web_development:
    image: postgres:14
    environment:
      - LC_ALL=C.UTF-8
      - POSTGRES_DB=web_development
      - POSTGRES_USER=web_development
      - POSTGRES_HOST_AUTH_METHOD=trust
    ports:
      # expose port 5432 to the host
      - '54321:5432'
  web_test:
    image: postgres:14
    environment:
      - LC_ALL=C.UTF-8
      - POSTGRES_DB=web_test
      - POSTGRES_USER=web_test
      - POSTGRES_HOST_AUTH_METHOD=trust
    ports:
      # expose port 5432 to the host
      - '54322:5432'" > docker-compose.yml
```
those entries are quite similar, they have different credentials for
`username` and `database`. Also they're exposed to host on different ports - development database
is exposed at port `54321` and test at `54322`. The `POSTGRES_HOST_AUTH_METHOD=trust`
option is added because otherwise we'd have to specify the password.
> We do not need a separate `Dockerfile` for the databases, we can
> directly specify the image to build from with `image: postgres:14`

The last step is to configure the connection from `web` to
`web_development` and `web_test`. Rails itself expects database to be
available at `localhost` but with this setup there are actually three
different hosts inside same network. So let's change corresponding
settings in `config/database.yml`:
```sh
# use proper hosts for the database
# connect to web_development instead of localhost in development
mutagen-compose exec web sed -i 's/#host: localhost/host: web_development/' config/database.yml
# use web_development user instead of root in development for connection
mutagen-compose exec web sed -i 's/#username: web/username: web_development/' config/database.yml
# same here - use proper username and hosthane
mutagen-compose exec web sed -i '/database: web_test/i \
  username: web_test\
  host: web_test' config/database.yml
```
there is no need to change some settings because `web_development` and
`web_test` are databases used by Rails by default since the project was
generated within the folder named `web`.

### Step 3 - Add mutagen

Mutagen is an open-source tool designed for fast and reliable file synchronization. There are
also other similar tools, like docker-sync but Mutagen has better performance and stability.
What is interesting for all Mac users is that Mutagen can be used with Docker®  on Mac, as a
tool for sync files between host and docker volume - it improves performance a lot.
On my local laptop I got consistent 4x performance boost with this setup.

It also has it's own compose tool `mutagen-compose`. Mutagen Compose is a project that provides
Mutagen integration with Docker® Compose, allowing you to automatically create Mutagen
synchronization and forwarding sessions alongside your Compose-based services, volumes,
and networks. We will be using it to build our images and start services.

First let's install mutagen-compose - I'm using Homebrew so it's quite straightforward for me
````sh
brew install mutagen-io/mutagen/mutagen-compose
````

next we add a new volume to our compose file:
```diff
- 23. echo "version: '3.8'
+ 23. echo "version: '3.8'
+ 24. volumes:
+ 25.   web:
```
and we mount this volume in our `web` service:
```diff
- 34.       - "..":/web:cached
+ 35.       - web:/web
```
the last thing is to tell mutagen to sync this volume with our local
folder
```sh
x-mutagen:
  sync:
    defaults:
      ignore:
        vcs: true
    web:
      alpha: '..'
      beta: 'volume://web'
      mode: 'two-way-resolved'"> compose.yml
```
alpha is set to be `..` since `compose.yml` is located inside
`.devcontainer` folder. I've also switched from `docker-compose.yml` to
`compose.yml` for convenience

#### Extra
**Ukraine is at WAR with Russia now! World history being written these
days - become one who was involved! Your grandchildren would love to
hear the stories!**
- **[Join our IT Army][it_army]{:target='_blank_'}**
- **[Spread the word][spread_word]{:target='_blank_'}**

**Слава Україні! Glory to Ukraine!**

In case you face issues try the following:
1. Stop all containers with `mutagen-compose down`
2. Delete any built images and volumes
3. Restart Docker® 
4. Start from the [Step 1](#step-1---switch-from-sqlite-to-postgresql-and-use-mutagen-compose)

#### Revisions
- Mar 07, 22
  - Switched from a separate `Dockerfile` for database to default image
  from Docker® 

[appl]: https://github.com/bpohoriletz/bpohoriletz.github.io/tree/master/samples/rails-7-app-inside-docker-on-osx-part-2
[gist]: https://gist.github.com/bpohoriletz/02879b77505bd430daa36f84ce1b9467
[mutagen_compose]: https://github.com/mutagen-io/mutagen-examples/blob/main/compose/web-go/compose.yml 
[part_one]: https://bpohoriletz.github.io/2022/01/19/rails-7-app-inside-docker-on-osx.html
[it_army]: https://t.me/itarmyofukraine2022
[spread_word]: https://www.pravda.com.ua/eng/
[mutagen]: https://accesto.com/blog/docker-on-mac-how-to-speed-it-up/
