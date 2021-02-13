#!/usr/bin/env make
SHELL := '/bin/bash'
LAST_TAG := $(shell git describe --tags --abbrev=0)

all: tests

# clean artifacts generated by make tests
clean:
	-rm -rf test.yml .venv/ nodiscc-xsrv-*.tar.gz gitea-cli/ .venv/ ansible_collections/

# install requirements for test suite
install_deps:
	apt update && apt -y install git bash python3-venv python3-pip ssh pwgen shellcheck jq

#####

tests: shellcheck check_readmes check_jinja2 ansible_syntax_check ansible_lint yamllint

# static syntax checker for shell scripts
shellcheck:
	# ignore 'Can't follow non-constant source' warnings
	shellcheck -e SC1090 xsrv


# check that all roles README.md contains expected sections/info
check_readmes:
	for i in roles/*/README.md; do grep '../../LICENSE' "$$i" >/dev/null || (echo "ERROR: missing license information in $$i"; exit 1); done

# install dev tools in virtualenv
venv:
	python3 -m venv .venv && \
	source .venv/bin/activate && \
	pip3 install wheel && \
	pip3 install isort ansible-lint cryptography==3.3.2 yamllint ansible==2.10.5

# build the ansible collection tag.gz
build_collection: venv bump_versions
	tag=$(LAST_TAG) && \
	source .venv/bin/activate && \
	ansible-galaxy collection build --force

# prepare the test environment
testenv: venv build_collection
	cp tests/playbook.yml test.yml
	source .venv/bin/activate && \
	tag=$(LAST_TAG) && \
	ansible-galaxy  -vvv collection install --collections-path ./ nodiscc-xsrv-$$tag.tar.gz

# Playbook syntax check
ansible_syntax_check: venv testenv
	source .venv/bin/activate && \
	ANSIBLE_COLLECTIONS_PATHS="./" ansible-playbook --syntax-check --inventory tests/inventory.yml test.yml

# Ansible syntax linter
ansible_lint: venv testenv
	source .venv/bin/activate && \
	ANSIBLE_COLLECTIONS_PATHS="./" ansible-lint -v test.yml

# YAML syntax check and linter
yamllint: venv
	source .venv/bin/activate && \
	set -o pipefail && \
	find roles/ -iname "*.yml" | xargs yamllint -c tests/.yamllint

# Jinja2 template syntax linter
check_jinja2: venv
	source .venv/bin/activate && \
	j2_files=$$(find roles/ -name "*.j2") && \
	for i in $$j2_files; do \
	echo "[INFO] checking syntax for $$i"; \
	python3 ./tests/check-jinja2.py "$$i"; \
	done

# Update TODO.md by fetching issues from the main gitea instance API
# requirements: gitea-cli config defined in ~/.config/gitearc
update_todo:
	git clone https://github.com/bashup/gitea-cli gitea-cli
	echo '<!-- This file is automatically generated by "make update_todo" -->' >| docs/TODO.md
	echo -e "\n### xsrv/xsrv\n" >> docs/TODO.md; \
	./gitea-cli/bin/gitea issues xsrv/xsrv | jq -r '.[] | "- #\(.number) - \(.title) - `\(.milestone.title)`"'  | sed 's/ - `null`//' >> docs/TODO.md
	rm -rf gitea-cli

# bump version numbers in repository files
bump_versions:
	tag=$(LAST_TAG) && \
	sed -i "s/^version:.*/version: $$tag/" galaxy.yml && \
	sed -i "s/^version=.*/version=\"$$tag\"/" xsrv && \
	sed -i "s/^version =.*/version = '$$tag'/" docs/conf.py && \
	sed -i "s/^release =.*/release = '$$tag'/" docs/conf.py && \
	sed -i "s/latest%20release-.*-blue/latest%20release-$$tag-blue/" README.md docs/index.md

# publish the ansible collection
# ANSIBLE_GALAXY_PRIVATE_TOKEN must be defined in the environment
publish_collection: venv bump_versions build_collection
	tag=$(LAST_TAG) && \
	source .venv/bin/activate && \
	ansible-galaxy collection publish --token "$$ANSIBLE_GALAXY_PRIVATE_TOKEN" nodiscc-xsrv-$$tag.tar.gz


# list all variables names from role defaults
# can be used to establish a list of variables that need to be checked via 'assert' tasks at the beginnning of the role
list_default_variables:
	for i in roles/*; do \
	echo -e "\n#### $$i #####\n"; \
	grep --no-filename -E --only-matching "^(# )?[a-z\_]*:" $$i/defaults/main.yml | sed 's/# //' | sort -u ; \
	done

# get build status of the current commit/branch
# GITLAB_PRIVATE_TOKEN must be defined in the environment
get_build_status:
	@branch=$$(git rev-parse --abbrev-ref HEAD) && \
	commit=$$(git rev-parse HEAD) && \
	curl --silent --header "PRIVATE-TOKEN: $$GITLAB_PRIVATE_TOKEN" "https://gitlab.com/api/v4/projects/nodiscc%2Fxsrv/repository/commits/$$commit/statuses?ref=$$branch" | jq  .[].status
	
# documentation generation
doc: install_dev_docs doc_html

# install documentation generator (sphinx + markdown + theme)
install_dev_docs:
	python3 -m venv .venv/
	source .venv/bin/activate && pip3 install sphinx recommonmark sphinx_rtd_theme


# HTML documentation generation (sphinx-build --help)
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = docs/    # source directory (markdown)
BUILDDIR      = doc/html  # destination directory (html)
doc_html:
	source .venv/bin/activate && sphinx-build -c doc/ -b html doc/ doc/html

