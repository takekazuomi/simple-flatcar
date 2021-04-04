RESOURCE_GROUP	?= takekazuomi-rg

BICEP		:= bicep
AZ		:= az
DEPLOY_NAME	= $(shell date +'deploy-%d%H%M%S')
LOG_DATE	:= $(shell date +'%d%H%M%S')
LOG_FILE	?= "logs/logs-"$(LOG_DATE).log
SSH_KEY_FILE	:= .secure/vm-keys
MY_IP_ADDRESS	:= $(shell curl -s 'https://api.ipify.org')
OPTIONS		= "-p adminSshKey=\"$$(cat $(SSH_KEY_FILE).pub)\" customData=\"$$(cat config.ign | base64 -w0)\" sourceAddressPrefix=\"$(MY_IP_ADDRESS)\""

CT		= docker run --rm -i quay.io/coreos/ct:latest-dev --platform=azure

AZURE_CORE_OUTPUT ?= table
export AZURE_CORE_OUTPUT
export AZURE_CORE_NO_COLOR = True

# keep intemidiate files usefull for debug
#.PRECIOUS: %.json

.DEFAULT_GOAL := help

help:           ## Show this help.
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)

%.json: %.bicep
	@$(BICEP) build $<

az-deploy: setup
	$(AZ) deployment group $(CMD) -g $(RESOURCE_GROUP) -n $(DEPLOY_NAME) \
		-f $(SOURCE) $(AZ_OPTIONS) 2>&1

$(SSH_KEY_FILE):
	@mkdir -p .secure
	@chmod 0700 .secure
	@echo -e 'y' | ssh-keygen -f $(SSH_KEY_FILE) -N "" > /dev/null

az-account:
	$(AZ) account list

%.deploy: %.bicep setup
	$(MAKE) az-deploy CMD="create" SOURCE=$< LOG_FILE=$(LOG_FILE) AZ_OPTIONS=$(OPTIONS) | tee -a $(LOG_FILE)

%.whatif: %.bicep setup
	# CMD="what-if --no-pretty-print"
	-@$(MAKE) az-deploy CMD="what-if" SOURCE=$< LOG_FILE=$(LOG_FILE) AZ_OPTIONS=$(OPTIONS) | tee -a $(LOG_FILE)
	#@grep -q Nochange $(LOG_FILE)

.PHONY: setup
setup: $(SSH_KEY_FILE) config.ign

clean:
	az group delete -g $(RESOURCE_GROUP)

config.ign: config.yml
	cat $< | $(CT) > $@

deploy:		## Deploy all
deploy: main.deploy

what-if:	## What if all
what-if: main.whatif

