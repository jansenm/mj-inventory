# SPDX-FileCopyrightText: 2021 Michael Jansen <info@michael-jansen.biz>
# SPDX-License-Identifier: CC0-1.0
ifndef VERBOSE
.SILENT:
endif

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))

##
## DEVELOP
## =======
all: build test

build: build-before build-npm build-mix build-after
build-mix: build-mix-before build-mix-do build-mix-after
build-mix-do:
	mix compile

build-npm: build-npm-before build-npm-do build-npm-after
build-npm-do:
	cd apps/inventory_web/assets && npm run deploy
	cd apps/inventory_web && mix phx.digest

rebuild: rebuild-before clean build rebuild-after

build-dependencies: build-dependencies-before build-dependencies-do build-dependencies-after
build-dependencies-do:
	mix deps.get
	mix deps.compile

##
## TEST
## ====
test: test-before build test-do test-after
test-do:
	mix test


##
## CLEAN STUFF
## ===========

## clean                 > clean-npm clean-hex
clean: clean-before clean-npm clean-mix clean-after

## clean-npm             $ rm -rf node_modules
clean-npm: clean-npm-before clean-npm-do clean-npm-after
clean-npm-do:
	rm -rf apps/inventory_web/assets/node_modules

veryclean-npm: veryclean-npm-before veryclean-npm-do veryclean-npm-after
veryclean-npm-do:
	npm cache clean --force

## clean-mix             $ mix clean
clean-mix: clean-mix-before clean-mix-do clean-mix-after
clean-mix-do:
	mix clean

##
## UPDATE DEPENDENCIES
## ===================

## outdated                > outdated-hex outdated-npm
outdated: outdated-before outdated-do outdated-after
outdated-do: outdated-hex outdated-npm

## outdated-hex          show outdated hex dependencies
outdated-hex: outdated-hex-before outdated-hex-do outdated-hex-after
outdated-hex-do:
	mix hex.outdated

## outdated-npm          show outdated npm dependencies
outdated-npm: outdated-npm-before outdated-npm-do outdated-npm-after
outdated-npm-do:
	cd apps/invdentory_web/assets && npm outdated

## update                > update-npm update-hex
update: update-before clean update-hex update-npm build-dependencies build test update-after

## update-npm            update the npm dependencies
update-npm: update-npm-before update-npm-do build-npm update-npm-after
update-npm-do:
	cd apps/inventory_web/assets && npm update --all
	cd apps/inventory_web/assets && npm install --mode=development

## update-hex            update the hex dependencies
update-hex: update-hex-before update-hex-do update-hex-after
update-hex-do:
	mix deps.update --all

##
## GENERAL
## =======

## help                  show help about the makefile
help:
	sed -n -e "s/^## \?\(.*\)/\1/p" "$(THIS_MAKEFILE)"

%-before:
	echo "**** making $*"
%-after:
	echo "**** finished $*"
