SHELL := /usr/bin/bash
.ONESHELL:

.PHONY: depends serve pkg/%

all: | depends serve

pkg/%:
	pkg="$${$@:1}"
	if [ -z " dpkg -l | grep $$pkg " ]; then
	  sudo apt-get install $$pkg
	fi

depends: pkg/ruby-dev pkg/ruby-bundler
	
serve:
	bundle install
	bundle exec jekyll serve