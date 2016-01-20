SHELL = /bin/bash

#MARKDOWN_PARSER = src/marked.js
MARKDOWN_PARSER = src/markdown-it.js

all: plugins/markdownwysiwyg/plugin.js tests/markdownwysiwyg/markdownwysiwyg.js tests/markdownwysiwyg/markdown_tools.js tests/markdownwysiwyg/markdown_common_mark.js

build/markdown-plugin.js: src/markdown-plugin.coffee
	mkdir -p $$(dirname $@)
	coffee -o build -c src/markdown-plugin.coffee

#plugins/markdownwysiwyg/plugin.js: src/marked.js build/markdown-plugin.js
plugins/markdownwysiwyg/plugin.js: $(MARKDOWN_PARSER) build/markdown-plugin.js
	mkdir -p $$(dirname $@)
	cat $< build/markdown-plugin.js > $@

prepare:
	npm install
	cd node_modules && git clone https://github.com/karlcow/markdown-testsuite.git

ALL_INPUT  = $(wildcard node_modules/markdown-testsuite/tests/*.md)
ALL_OUTPUT = $(wildcard node_modules/markdown-testsuite/tests/*.out)

tests/markdownwysiwyg/markdownwysiwyg.js: tools/make_test
	mkdir -p $$(dirname $@)
	tools/make_test $(ALL_INPUT) > $@

tests/markdownwysiwyg/markdown_common_mark.js: tools/make_test_common_mark
	mkdir -p $$(dirname $@)
	cd tools && ./make_test_common_mark > ../$@

build/markdown_tools.js: src/markdown_tools.coffee
	mkdir -p $$(dirname $@)
	coffee -o build -c $<

tests/markdownwysiwyg/markdown_tools.js: build/markdown_tools.js
	echo "/* bender-tags: editor,unit */" > $@
	echo "/* bender-ckeditor-plugins: markdownwysiwyg,entities,enterkey */" >> $@
	cat $< >> $@


CWD = $(shell pwd)

install-dev:
	if [[ -z "$(CKEDITOR_DEV)" ]] ; then \
		echo "usage: make install CKEDITOR_DEV=<path>" ;\
		exit 1 ; \
	else \
		exit 0; \
	fi

	[[ -z "$(CKEDITOR_DEV)" ]] && (echo "usage: make install CKEDITOR_DEV=<path>" && exit 1) || exit 0
	[[ ! -e $(CKEDITOR_DEV)/tests/plugins/markdownwysiwyg ]] && cd $(CKEDITOR_DEV)/tests/plugins && ln -s $(CWD)/tests/markdownwysiwyg
	[[ ! -e $(CKEDITOR_DEV)/plugins/markdownwysiwyg ]] && cd $(CKEDITOR_DEV)/plugins && ln -s $(CWD)/plugins/markdownwysiwyg

/home/kiwi/github/gollum-caves/public/gollum-caves/javascript/ckeditor/plugins/markdownwysiwyg/plugin.js: plugins/markdownwysiwyg/plugin.js
	cp $< $@

deploy-gollum-caves: /home/kiwi/github/gollum-caves/public/gollum-caves/javascript/ckeditor/plugins/markdownwysiwyg/plugin.js

.PHONY: all
