
-include Makefile.config

export LIVEBOOK_HOME            := livebook/livebook_notebooks
export LIVEBOOK_APPS_PATH       := livebook/livebook_apps
export LIVEBOOK_DATA_PATH       := livebook/livebook_data
export LIVEBOOK_DEFAULT_RUNTIME ?= attached:$(ELIXIR_NODE_NAME):$(ELIXIR_NODE_COOKIE)

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))

ifndef VERBOSE
.SILENT:
endif

.DEFAULT_GOAL = build

##
## RUN
## ==========================================================================

## info                 Show Information about the project
info: .cookie
	echo "  SNAME=$(SNAME)"
	echo " COOKIE=$(COOKIE)"
	echo "PROJECT=$(PROJECT)"

.cookie:
	# Make sure the tools is installed / available
	type -p uuidgen >/dev/null
	if ! test -e .cookie; then \
		uuidgen > .cookie; \
	fi

## iex                  Start interactive IEX Session (needs dev environment)
iex: .cookie
	env MIX_ENV=dev iex --name "$(ELIXIR_NODE_NAME)" --cookie "$(ELIXIR_NODE_COOKIE)" -S mix

## livebook             Start a livebook (needs the iex session)
.PHONY: livebook
livebook:
	livebook server

##
## DEVELOP
## ==========================================================================

## build                -> build-mix build-assets
build: build-before build-dependencies build-mix build-after

## build-mix            -> »mix compile«
build-mix: build-mix-before build-mix-do build-mix-after
build-mix-do:
	mix compile + escript.build

## rebuild              -> clean build
rebuild: rebuild-before clean build rebuild-after

## build-dependencies   »mix deps.get + deps.compile«
build-dependencies: build-dependencies-before build-dependencies-do build-dependencies-after
build-dependencies-do:
	mix deps.get + deps.compile


##
## TRANSLATION
## ==========================================================================
## gettext              -> gettext.extract, gettext-merge
gettext: gettext-before gettext-extract gettext-merge gettext-after
## gettext.extract      -> extract messages from source code
gettext-extract:
	@echo "1"
	mix gettext.extract
## gettext.extract      -> merge template files in message files
gettext-merge:
	@echo "2"
	mix gettext.merge priv/gettext

##
## TEST
## ==========================================================================
## test                 Run the unit tests (needs test environment)
test: test-before test-do test-after
test-do:
	mix test

## cover                Run the unit tests with cover (needs test environment)
cover: cover-before cover-do cover-after
cover-do:
	mix test --export-coverage default --cover
	mix test.coverage

##
## CODE QUALITY
## ==========================================================================
## check                -> check-mix
check: credo dialyzer

## credo                Run the credo tool
credo: credo-before credo-do credo-after
credo-do:
	mix credo

## dialyzer             Run the dialyzer tool
dialyzer: dialyzer-before dialyzer-do dialyzer-after
dialyzer-do:
	mix dialyzer

## docs                 Create source documentation
docs: docs-before docs-do docs-after
docs-do:
	mix docs

##
## CLEANUP
## ==========================================================================

## clean                > clean-npm clean-hex
clean: clean-before clean-mix clean-after

## clean-mix            $ mix clean
clean-mix: clean-mix-before clean-mix-do clean-mix-after
clean-mix-do:
	mix clean

##
## UPDATE DEPENDENCIES
## ==========================================================================

## outdated             > outdated-hex outdated-npm
outdated: outdated-before outdated-do outdated-after
outdated-do: outdated-hex

## outdated-hex         show outdated hex dependencies
outdated-hex: outdated-hex-before outdated-hex-do outdated-hex-after
outdated-hex-do:
	mix hex.outdated

## update               > update-npm update-hex
update: update-before clean update-hex build-dependencies build test update-after

## update-hex           update the hex dependencies
update-hex: update-hex-before update-hex-do update-hex-after
update-hex-do:
	mix deps.update --all

##
## ENVIRONMENT VARIABLES
## ==========================================================================

## VERBOSE              If defined print all commands

##
## MISCELLANOUS
##

## help                 Show help for the Makefile
help:
	sed -n -e "s/^## \?\(.*\)/\1/p" "$(THIS_MAKEFILE)"

# HELPER
%-before:
	echo ".... making $*"
%-after:
	echo ".... finished $*"

