###
### OPEN HORIZON TOP-LEVEL makefile
###

##
## things TO change - create your own HZN_HZN_ORG_ID_ID and URL files.
##

HZN_ORG_ID ?= $(if $(wildcard HZN_ORG_ID),$(shell cat HZN_ORG_ID),dcmartin@us.ibm.com)
URL ?= $(if $(wildcard URL),$(shell cat URL),com.github.dcmartin.open-horizon)
DOCKER_HUB_ID ?= $(shell whoami)

# tag this build environment
TAG ?= $(if $(wildcard TAG),$(shell cat TAG),)

# hard code architecture for build environment
BUILD_ARCH ?= $(if $(wildcard BUILD_ARCH),$(shell cat BUILD_ARCH),)

##
## things NOT TO change
##

SERVICES = cpu hal wan yolo base-alpine base-ubuntu herald mqtt base-hzncli
PATTERNS = yolo2msghub motion2mqtt

ALL = $(SERVICES) $(PATTERNS)

##
## targets
##

TARGETS = build-all push-all check test run remove clean distclean service-publish service-verify service-start service-test service-stop

## actual

default: $(ALL)

all: build service-publish service-verify service-start service-test pattern-publish pattern-validate

$(ALL):
	@echo "--- MAKE -- making $@"
	@$(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) -C $@

$(TARGETS):
	@echo "--- MAKE -- making $@ in ${ALL}"
	@for dir in $(ALL); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) -C $$dir $@; \
	done

pattern-publish:
	@echo "--- MAKE -- publishing $(PATTERNS)"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) -C $$dir $@; \
	done

pattern-validate: 
	@echo "--- MAKE -- validating $(PATTERNS)"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) -C $$dir $@; \
	done

.PHONY: $(SERVICES) $(PATTERNS) default all build run check stop push publish verify clean start test
