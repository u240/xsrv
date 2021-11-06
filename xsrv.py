#!/usr/bin/env python3
import os
import sys
import re
import subprocess
import logging
import argparse
logging.basicConfig(encoding='utf-8', level=logging.DEBUG)
ANSIBLE_TARGET_VERSION = '2.11.6'
PROJECTS_DIR = os.getenv('HOME') + '/playbooks'

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers()
deploy_parser = subparsers.add_parser('deploy', help='Run the main playbook')
deploy_parser.add_argument('project', type=str, nargs='?', help='Project name', default='test')
args = parser.parse_args()

ansible_venv_dir = PROJECTS_DIR + '/' + args.project + '/.venv'
ansible_venv_bin_dir = ansible_venv_dir + '/bin'
ansible_venv_bin_python = ansible_venv_bin_dir + '/python'
if not os.access(ansible_venv_bin_python, os.X_OK):
    logging.info('%s does not exist, creating virtualenv' % ansible_venv_bin_python)
    process = subprocess.Popen(['/usr/bin/env', 'python3', '-m', 'venv', ansible_venv_dir])
    process.wait()

ansible_bin = ansible_venv_bin_dir + '/ansible'
try:
    ansible_version_sp = subprocess.Popen([ansible_bin, '--version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = ansible_version_sp.communicate()
    ansible_version = re.search(r'[0-9]*\.[0-9]*\.[0-9]*', str(output.splitlines()[0]))[0]
    if ansible_version != ANSIBLE_TARGET_VERSION:
        logging.info('ansible version: %s - target version: %s, attempting to upgrade' % (ansible_version, ANSIBLE_TARGET_VERSION))
        logging.error('TODO - NOT IMPLEMENTED')
        exit(1)
    else:
        logging.info('ansible version: %s - target version: %s, OK' % (ansible_version, ANSIBLE_TARGET_VERSION))
except FileNotFoundError:
    logging.info('%s not installed, installing' % ansible_bin)
    install_ansible_sp = subprocess.Popen([ansible_venv_bin_python, '-m', 'pip', 'install', 'ansible'])
    install_ansible_sp.wait()

sp = subprocess.Popen([ansible_bin, '--version'], shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
output, error = sp.communicate()

#print(ansible_version)
#print(out)
