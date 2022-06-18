PROJECT_FOLDER=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
DOCKER_IMAGE_NAME=tf_gcp_static_website
RUN_IN_DOCKER := python -u $(PROJECT_FOLDER)/third_party/project-utils/src/run_in_docker.py $(RUN_IN_DOCKER_OPTIONS) --working-dir $(PROJECT_FOLDER) $(DOCKER_IMAGE_NAME)

#############################################################################
# Lint
#############################################################################

.PHONY: lint
lint:
	$(RUN_IN_DOCKER) terraform \
		'terraform init' \
		'tflint --config=.tflint.hcl .' \
		'terraform validate' \
		'terraform fmt'

#############################################################################
# Shell
#############################################################################
