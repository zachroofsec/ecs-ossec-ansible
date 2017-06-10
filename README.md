# General Info
This playbook orchestrates an OSSEC Client and Server environment through AWS Elastic Container Service.
The client finds the server through a Private Hosted Zone within the created VPC (`manager.ossec`)

You don't need to build the docker environments found in `docker-ossec-client` and `docker-ossec-server`.
These have been built and pushed to `https://hub.docker.com/r/zroof/ossec_server/` and `https://hub.docker.com/r/zroof/ossec_client/`

You'll notice some items that say `PROD-TODO:`.  If you're deploying into PROD, these are some extra considerations that might be investigated :D

# Requirements
1) Latest Boto Client (`pip install boto`)
2) Ansible 2.4 or greater (`pip install git+git://github.com/ansible/ansible.git@devel`)
  * As of 6/7/2017 Ansible 2.4 is in devel branch
3) aws cli (`pip install --upgrade --user awscli`)

4) AWS credentials with a poweruser role attached
  * `export AWS_ACCESS_KEY_ID=foo`
  * `export AWS_SECRET_ACCESS_KEY=bar`

5) `ansible-playbook main_playbook.yml` :D
