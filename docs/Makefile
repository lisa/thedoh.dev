SHELL := bash
DOCSDIR := .
RUBYVER := ruby-2.5.1
ACTIVERUBY := $(shell rvm current)
SITEFILES := $(shell find $(DOCSDIR) -name "*.y*ml" -or -name "*.md" |grep  -E -v "^./(vendor|_site)")
MDFILES := $(shell find $(DOCSDIR) -name "*.md" |grep  -E -v "^./(vendor|_site)")
TOC := $(DOCSDIR)/_data/toc.yaml

.PHONY: setrubyver
setrubyver:
	if [[ "$(ACTIVERUBY)" != "$(RUBYVER)" ]] ;\
	then rvm use $(RUBYVER) ;\
	fi

serve: toc setrubyver $(SITEFILES)
	bundle exec jekyll serve

build: $(SITEFILES)
	bundle exec jekyll build

.PHONY: clean
clean:
	rm -rf _site

toc: $(SITEFILES)
	ruby scripts/createtoc.rb $(DOCSDIR) $(MDFILES)
