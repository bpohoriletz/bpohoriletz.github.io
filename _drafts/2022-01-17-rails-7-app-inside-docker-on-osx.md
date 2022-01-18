---
layout: post
post_title: '[EN] Part 1 - Rails 7 application inside Docker on macOS'
title: '[EN] Part 1 - Rails 7 application inside Docker on macOS'
description: 'How to create Rails 7 app with all dependencies hidden inside a
Docker container'
lang: 'enUS'
---
* Time: 5-10 min
* Level: Beginner/Intermediate
* Code: [Gist][gist]{:target='_blank_'}
* References:
  * [Graceful Dev – Avdi Grimm][avdi]{:target='_blank_'}
  * [Docker Docs][dock]{:target='_blank_'}
  * [Alpine, Slim, Stretch, Buster, Jessie, Bullseye — What are the Differences in Docker Images? - Julie Perilla Garcia][juli]{:target='_blank_'}

Sometimes we want to play with the new version of Ruby/Rails, but in
order to do so we need to install dependencies which quite often is not
so seamless. So let's take a look how to use Docker and shell commands in
order to quickly start new project with any combination of Ruby/Rails
version.

#### TL;DR - [Gist][gist]{:target='_blank_'}

[gist]: https://gist.github.com/bpohoriletz/9ba8c5a8eb92727ec24dccfe269f5ea8
[avdi]: https://graceful.dev/courses/tapastry/modules/2021/
[dock]: https://docs.docker.com/compose/compose-file/compose-file-v3/
[juli]: https://medium.com/swlh/alpine-slim-stretch-buster-jessie-bullseye-bookworm-what-are-the-differences-in-docker-62171ed4531d
