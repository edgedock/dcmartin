###
### OPEN HORIZON TOP-LEVEL makefile
###

##
## things TO change
##

ORG = dcmartin@us.ibm.com
URL = com.github.dcmartin.open-horizon
DOCKER_ID ?= $(shell whoami)

##
## things NOT TO change
##

SERVICES = cpu hal wan yolo
PATTERNS = yolo2msghub # motion

ALL = $(SERVICES) $(PATTERNS)

default: $(SERVICES) check

all: $(ALL)

$(ALL):
	$(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $@

build:
	for dir in $(ALL); do \
	  $(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

push:
	for dir in $(ALL); do \
	  $(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

check:
	for dir in $(ALL); do \
	  $(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

run:
	for dir in $(ALL); do \
	  $(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

remove:
	for dir in $(ALL); do \
	  $(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

clean:
	for dir in $(ALL); do \
	  $(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

publish:
	for dir in $(ALL); do \
	  $(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

start:
	for dir in $(PATTERNS); do \
	  $(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

verify:
	for dir in $(SERVICES); do \
	  $(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

pattern:
	for dir in $(PATTERNS); do \
	  $(MAKE) URL=$(URL) ORG=$(ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

.PHONY: $(SERVICES) $(PATTERNS) default all build run check stop push publish verify clean depend start
