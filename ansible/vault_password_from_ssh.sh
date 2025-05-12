#!/bin/bash
# Generate vault password from SSH key
ssh-keygen -y -f ./keys/id_ed25519_ansible_vault | md5sum | awk '{print $1}'