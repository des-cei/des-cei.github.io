#!/bin/bash

sudo -H apt-get install ruby-dev #libxml2-dev zlib1g-dev

sudo -H gem install bundler
bundle install
bundle update

bundle exec jekyll serve
