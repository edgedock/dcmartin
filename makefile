###
### OPEN HORIZON TOP-LEVEL makefile
###

##
## things TO change
##

HZN_ORG = dcmartin@us.ibm.com
HZN_URL = com.github.dcmartin.open-horizon
DOCKER_ID = $(shell whoami)

##
## things NOT TO change
##

HEU = https://alpha.edge-fabric.com/v1/ 
SERVICES = cpu hal wan yolo
PATTERNS = yolo2msghub motion

default: $(SERVICES)

all: $(SERVICES) $(PATTERNS)

$(PATTERNS) $(SERVICES):
	$(MAKE) HEU=$(HEU) HZN_ORG=$(HZN_ORG) DOCKER_ID=$(DOCKER_ID) -C $@

build:
	for dir in $(SERVICES) $(PATTERNS); do \
	  $(MAKE) HEU=$(HEU) HZN_ORG=$(HZN_ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

check:
	for dir in $(SERVICES) $(PATTERNS); do \
	  $(MAKE) HEU=$(HEU) HZN_ORG=$(HZN_ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

run:
	for dir in $(SERVICES); do \
	  $(MAKE) HEU=$(HEU) HZN_ORG=$(HZN_ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

remove:
	for dir in $(SERVICES); do \
	  $(MAKE) HEU=$(HEU) HZN_ORG=$(HZN_ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done


clean:
	for dir in $(SERVICES); do \
	  $(MAKE) HEU=$(HEU) HZN_ORG=$(HZN_ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

publish:
	for dir in $(SERVICES); do \
	  $(MAKE) HEU=$(HEU) HZN_ORG=$(HZN_ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

start:
	for dir in $(PATTERNS); do \
	  $(MAKE) HEU=$(HEU) HZN_ORG=$(HZN_ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

verify:
	for dir in $(SERVICES); do \
	  $(MAKE) HEU=$(HEU) HZN_ORG=$(HZN_ORG) DOCKER_ID=$(DOCKER_ID) -C $$dir $@; \
	done

.PHONY: $(SERVICES) $(PATTERNS) default all build run check stop push publish verify clean depend start
