SHELL = /bin/bash

all: plugins/markdown/plugin.js tests/markdown/markdown.js

build/markdown-plugin.js: src/markdown-plugin.coffee
	mkdir -p build
	coffee -o build -c src/markdown-plugin.coffee

plugins/markdown/plugin.js: src/marked.js build/markdown-plugin.js
	cat $< build/markdown-plugin.js > $@

prepare:
	npm install
	cd node_modules && git clone https://github.com/karlcow/markdown-testsuite.git

ALL_INPUT  = $(wildcard node_modules/markdown-testsuite/tests/*.md)
ALL_OUTPUT = $(wildcard node_modules/markdown-testsuite/tests/*.out)

tests/markdown/markdown.js: tools/make_test
	tools/make_test $(ALL_INPUT) > $@

CWD = $(shell pwd)

install-dev:
	if [[ -z "$(CKEDITOR_DEV)" ]] ; then \
		echo "usage: make install CKEDITOR_DEV=<path>" ;\
		exit 1 ; \
	else \
		exit 0; \
	fi

	[[ -z "$(CKEDITOR_DEV)" ]] && (echo "usage: make install CKEDITOR_DEV=<path>" && exit 1) || exit 0
	[[ ! -e $(CKEDITOR_DEV)/tests/plugins/markdown ]] && cd $(CKEDITOR_DEV)/tests/plugins && ln -s $(CWD)/tests/markdown
	[[ ! -e $(CKEDITOR_DEV)/plugins/markdown ]] && cd $(CKEDITOR_DEV)/plugins && ln -s $(CWD)/plugins/markdown

.PHONY: all
