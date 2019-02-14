###
### OPEN HORIZON TOP-LEVEL makefile
###

##
## things TO change
##

ORG = dcmartin@us.ibm.com
URL = com.github.dcmartin.open-horizon
TAG ?= $(if $(wildcard TAG),$(shell cat TAG),)
# BUILD_ARCH ?= $(if $(wildcard BUILD_ARCH),$(shell cat BUILD_ARCH),)
DOCKER_ID ?= $(shell whoami)

##
## things NOT TO change
##

SERVICES = cpu hal wan yolo base-alpine base-ubuntu base-hzncli herald 
PATTERNS = yolo2msghub motion2mqtt

ALL = $(SERVICES) $(PATTERNS)

##
## targets
##

TARGETS = build push check run remove clean publish verify stop

## actual

default: $(ALL) check

all: build publish verify start test pattern validate

$(ALL):
	@echo "--- INFO -- making $@"
	@$(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $@

$(TARGETS):
	@echo "--- INFO -- making $@ in ${ALL}"
	@for dir in $(ALL); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

start: build publish
	@echo "--- INFO -- starting $(PATTERNS)"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

test:
	@echo "--- INFO -- testing $(PATTERNS)"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

pattern:
	@echo "--- INFO -- publishing $(PATTERNS)"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

validate: 
	@echo "--- INFO -- validating $(PATTERNS)"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

.PHONY: $(SERVICES) $(PATTERNS) default all build run check stop push publish verify clean start test
