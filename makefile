###
### OPEN HORIZON TOP-LEVEL makefile
###

##
## things TO change
##

ORG = dcmartin@us.ibm.com
URL = com.github.dcmartin.open-horizon
TAG ?= beta
DOCKER_ID ?= $(shell whoami)

##
## things NOT TO change
##

SERVICES = base-alpine base-ubuntu cpu hal wan yolo herald hzncli-ubuntu
PATTERNS = yolo2msghub # motion

ALL = $(SERVICES) $(PATTERNS)

##
## targets
##

TARGETS = build push check run remove clean publish verify stop

## actual

default: $(ALL) check

all: build publish verify start test pattern validate

$(ALL):
	@$(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $@

$(TARGETS):
	@echo "--- INFO -- making ${TARGETS}"
	@for dir in $(ALL); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

start: build publish
	@echo "--- INFO -- starting"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

test:
	@echo "--- INFO -- testing"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

pattern:
	@echo "--- INFO -- publishing patterns"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

validate: 
	@echo "--- INFO -- validating patterns"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

.PHONY: $(SERVICES) $(PATTERNS) default all build run check stop push publish verify clean start test
