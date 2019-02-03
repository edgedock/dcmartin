###
### OPEN HORIZON TOP-LEVEL makefile
###

##
## things TO change
##

ORG = dcmartin@us.ibm.com
URL = com.github.dcmartin.open-horizon
TAG ?= -beta
DOCKER_ID ?= $(shell whoami)

##
## things NOT TO change
##

SERVICES = cpu hal wan yolo
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
	$(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $@

$(TARGETS):
	@for dir in $(ALL); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

start:
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

test:
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

pattern:
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

validate: 
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

.PHONY: $(SERVICES) $(PATTERNS) default all build run check stop push publish verify clean depend start test
