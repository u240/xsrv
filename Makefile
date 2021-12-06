#!/usr/bin/env make
SHELL := '/bin/bash'
LAST_TAG := $(shell git describe --tags --abbrev=0)

all: tests

##### TESTS #####

.PHONY: tests # run all tests
tests: test_shellcheck test_jinja2 test_ansible_syntax_check test_ansible_lint test_yamllint

.PHONY: test_shellcheck # static syntax checker for shell scripts
test_shellcheck:
	# ignore 'Can't follow non-constant source' warnings
	shellcheck -e SC1090 xsrv

.PHONY: venv # install dev tools in virtualenv
venv:
	python3 -m venv .venv && \
	source .venv/bin/activate && \
	pip3 install wheel && \
	pip3 install isort ansible-lint yamllint ansible==5.2.0

.PHONY: build_collection # build the ansible collection tar.gz
build_collection: venv
	source .venv/bin/activate && \
	ansible-galaxy collection build --force

.PHONY: install_collection # prepare the test environment/install the collection
install_collection: venv build_collection
	cp tests/playbook.yml test.yml
	source .venv/bin/activate && \
	ansible-galaxy  -vvv collection install --collections-path ./ nodiscc-xsrv-$(LAST_TAG).tar.gz

.PHONY: test_ansible_syntax_check # ansible playbook syntax check
test_ansible_syntax_check: venv install_collection
	source .venv/bin/activate && \
	ANSIBLE_COLLECTIONS_PATHS="./" ansible-playbook --syntax-check --inventory tests/inventory.yml test.yml

.PHONY: ansible_lint # ansible syntax linter
test_ansible_lint: venv install_collection
	source .venv/bin/activate && \
	ANSIBLE_COLLECTIONS_PATHS="./" ansible-lint -v test.yml

.PHONY: test_yamllint # YAML syntax check and linter
test_yamllint: venv
	source .venv/bin/activate && \
	set -o pipefail && \
	find roles/ -iname "*.yml" | xargs yamllint -c tests/.yamllint

.PHONY: test_molecule # test collection with molecule
test_molecule: venv
	python3 -m venv .venv && \
	source .venv/bin/activate && \
	pip3 install molecule docker molecule[docker] && \
	molecule --version && \
	molecule test

.PHONY: test_jinja2 # Jinja2 template syntax linter
test_jinja2: venv
	source .venv/bin/activate && \
	j2_files=$$(find roles/ -name "*.j2") && \
	for i in $$j2_files; do \
	echo "[INFO] checking syntax for $$i"; \
	python3 ./tests/check-jinja2.py "$$i"; \
	done


##### RELEASE PROCEDURE #####
# - make bump_versions update_todo changelog new_tag=$new_tag
# - update changelog.md, add and commit version bumps and changelog updates
# - git tag $new_tag; git push && git push --tags
# - git checkout release && git merge master && git push
# - GITLAB_PRIVATE_TOKEN=AAAbbbCCCddd make gitlab_release new_tag=$new_tag
# - GITHUB_PRIVATE_TOKEN=XXXXyyyZZZzz make github_release new_tag=$new_tags
# - ANSIBLE_GALAXY_PRIVATE_TOKEN=AAbC make publish_collection new_tag=$new_tag
# - update release descriptions on https://github.com/nodiscc/xsrv/releases and https://gitlab.com/nodiscc/xsrv/-/releases

.PHONY: bump_versions # manual - bump version numbers in repository files (new_tag=X.Y.Z required)
bump_versions: doc_md
ifndef new_tag
	$(error new_tag is undefined)
endif
	@sed -i "s/^version:.*/version: $(new_tag)/" galaxy.yml && \
	sed -i "s/^version=.*/version=\"$(new_tag)\"/" xsrv && \
	sed -i "s/^version =.*/version = '$(new_tag)'/" docs/conf.py && \
	sed -i "s/^release =.*/release = '$(new_tag)'/" docs/conf.py && \
	sed -i "s/latest%20release-.*-blue/latest%20release-$(new_tag)-blue/" README.md docs/index.md

# requires gitea-cli configuration in ~/.config/gitearc:
# export GITEA_API_TOKEN="AAAbbbCCCdddZZ"
# gitea.issues() {
# 	split_repo "$1"
# 	auth curl --silent --insecure "https://gitea.example.org/api/v1/repos/$REPLY/issues?limit=1000"
# }
.PHONY: update_todo # manual - Update TODO.md by fetching issues from the main gitea instance API
update_todo:
	git clone https://github.com/bashup/gitea-cli gitea-cli
	echo '<!-- This file is automatically generated by "make update_todo" -->' >| docs/TODO.md
	echo -e "\n### xsrv/xsrv\n" >> docs/TODO.md; \
	./gitea-cli/bin/gitea issues xsrv/xsrv | jq -r '.[] | "- #\(.number) - \(.title) - **`\(.milestone.title // "-")`** `\(.labels | map(.name) | join(","))`"'  | sed 's/ - `null`//' >> docs/TODO.md
	rm -rf gitea-cli

.PHONY: changelog # manual - establish a changelog since the last git tag
changelog:
	@echo "[INFO] changes since last tag $(LAST_TAG)" && \
	git log --oneline $(LAST_TAG)...HEAD | cat

.PHONY: gitlab_release # create a new gitlab release (new_tag=X.Y.Z required, GITLAB_PRIVATE_TOKEN must be defined in the environment)
gitlab_release:
ifndef new_tag
	$(error new_tag is undefined)
endif
ifndef GITLAB_PRIVATE_TOKEN
	$(error GITLAB_PRIVATE_TOKEN is undefined)
endif
	curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: $$GITLAB_PRIVATE_TOKEN" \
	--data '{ "name": "$(new_tag)", "tag_name": "$(new_tag)" }' \
	--request POST "https://gitlab.com/api/v4/projects/14306200/releases"

.PHONY: github_release # create a new github release (new_tag=X.Y.Z required, GITHUB_PRIVATE_TOKEN must be defined in the environement)
github_release:
ifndef new_tag
	$(error new_tag is undefined)
endif
ifndef GITHUB_PRIVATE_TOKEN
	$(error GITHUB_PRIVATE_TOKEN is undefined)
endif
	curl --user nodiscc:$$GITHUB_PRIVATE_TOKEN --header "Accept: application/vnd.github.v3+json" \
	--data '{ "tag_name": "$(new_tag)", "prerelease": true }' \
	--request POST https://api.github.com/repos/nodiscc/xsrv/releases

.PHONY: publish_collection # publish the ansible collection (ANSIBLE_GALAXY_PRIVATE_TOKEN must be defined in the environment)
publish_collection: build_collection
ifndef new_tag
	$(error new_tag is undefined)
endif
ifndef ANSIBLE_GALAXY_PRIVATE_TOKEN
	$(error ANSIBLE_GALAXY_PRIVATE_TOKEN is undefined)
endif
	source .venv/bin/activate && \
	ansible-galaxy collection publish --token "$$ANSIBLE_GALAXY_PRIVATE_TOKEN" nodiscc-xsrv-$(new_tag).tar.gz


##### UTILITIES #####

.PHONY: install_deps # manual - install requirements for test suite
install_deps:
	apt update && apt -y install git bash python3-venv python3-pip python3-cryptography ssh pwgen shellcheck jq

# can be used to establish a list of variables that need to be checked via 'assert' tasks at the beginnning of the role
.PHONY: list_default_variables # manual - list all variables names from role defaults
list_default_variables:
	for i in roles/*; do \
	echo -e "\n#### $$i #####\n"; \
	grep --no-filename -E --only-matching "^(# )?[a-z\_]*:" $$i/defaults/main.yml | sed 's/# //' | sort -u ; \
	done

.PHONY: get_build_status # manual - get build status of the current commit/branch (GITLAB_PRIVATE_TOKEN must be defined in the environment)
get_build_status:
ifndef GITLAB_PRIVATE_TOKEN
	$(error GITLAB_PRIVATE_TOKEN is undefined)
endif
	@branch=$$(git rev-parse --abbrev-ref HEAD) && \
	commit=$$(git rev-parse HEAD) && \
	curl --silent --header "PRIVATE-TOKEN: $$GITLAB_PRIVATE_TOKEN" "https://gitlab.com/api/v4/projects/nodiscc%2Fxsrv/repository/commits/$$commit/statuses?ref=$$branch" | jq  .[].status

.PHONY: doc_md # manual - generate docs/index.md from README.md
doc_md:
	@roles_list_md=$$(for i in roles/*/meta/main.yml; do \
		name=$$(grep "role_name: " "$$i" | awk -F': ' '{print $$2}'); \
		description=$$(grep "description: " "$$i" | awk -F': ' '{print $$2}' | sed 's/"//g'); \
		echo "- [$$name](roles/$$name) - $$description"; \
		done) && \
		echo "$$roles_list_md" >| roles-list.tmp.md
	@awk ' \
		BEGIN {p=1} \
		/^<!--BEGIN ROLES LIST-->/ {print;system("cat roles-list.tmp.md | sort --version-sort");p=0} \
		/^<!--END ROLES LIST-->/ {p=1} \
		p' README.md >> README.tmp.md
	@rm roles-list.tmp.md
	@mv README.tmp.md README.md
	@cp README.md docs/index.md
	@sed -i 's|(roles/|(https://gitlab.com/nodiscc/xsrv/-/tree/master/roles/|g' docs/index.md
	@sed -i 's|https://xsrv.readthedocs.io/en/latest/\(.*\).html|\1.md|g' docs/index.md
	@sed -i 's|docs/||g' docs/index.md

SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = docs/    # source directory (markdown)
BUILDDIR      = doc/html  # destination directory (html)
.PHONY: doc_html # manual - HTML documentation generation (sphinx-build --help)
doc_html: doc_md
	python3 -m venv .venv/ && \
	source .venv/bin/activate && \
	pip3 install sphinx recommonmark sphinx_rtd_theme && \
	sphinx-build -c docs/ -b html docs/ docs/html

.PHONY: clean # manual - clean artifacts generated by make tests
clean:
	-rm -rf test.yml .venv/ nodiscc-xsrv-*.tar.gz gitea-cli/ .venv/ ansible_collections/ .cache/
