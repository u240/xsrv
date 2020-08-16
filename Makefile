#!/usr/bin/env make
SHELL := '/bin/bash'

tests: shellcheck check_jinja2 ansible_syntax_check ansible_lint yamllint clean

# Install dev tools in virtualenv
venv:
	python3 -m venv .venv && \
	source .venv/bin/activate && \
	pip3 install isort ansible-lint yamllint ansible==2.9.3

# Static syntax checker for shell scripts
# requirements: sudo apt install shellcheck
shellcheck:
	# ignore 'Can't follow non-constant source' warnings
	shellcheck -e SC1090 xsrv

testenv:
	cp tests/playbook.yml test.yml

clean:
	-rm -r test.yml .venv/

# Playbook syntax check
ansible_syntax_check: venv testenv
	source .venv/bin/activate && \
	ansible-playbook --syntax-check --inventory tests/inventory.yml test.yml

# Ansible linter
ansible_lint: venv testenv
	source .venv/bin/activate && \
	ansible-lint test.yml

# YAML syntax check and linter
yamllint: venv
	source .venv/bin/activate && \
	set -o pipefail && \
	find roles/ -iname "*.yml" | xargs yamllint -c tests/.yamllint

check_jinja2: venv
	source .venv/bin/activate && \
	j2_files=$$(find roles/ -name "*.j2") && \
	for i in $$j2_files; do \
	echo "[INFO] checking syntax for $$i"; \
	python3 ./tests/check-jinja2.py "$$i"; \
	done

# Update TODO.md by fetching issues from the main gitea instance API
# requirements: sudo apt install git jq
#               gitea-cli config defined in ~/.config/gitearc
update_todo:
	git clone https://github.com/bashup/gitea-cli gitea-cli
	echo '<!-- This file is automatically generated by "make update_todo" -->' >| docs/TODO.md
	echo -e "\n### xsrv/xsrv\n" >> docs/TODO.md; \
	./gitea-cli/bin/gitea issues xsrv/xsrv | jq -r '.[] | "- #\(.number) - \(.title)"' >> TODO.md;o
	rm -rf gitea-cli

# build and publish the ansible collection
publish_collection: venv
	source .venv/bin/activate && \
	ansible-galaxy collection build && \
	ansible-galaxy collection publish nodiscc-xsrv-0.18.0.tar.gz
