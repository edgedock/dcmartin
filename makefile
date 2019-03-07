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

BASES = base-alpine base-ubuntu hzncli
SERVICES =  cpu hal wan yolo  herald mqtt yolo4motion
PATTERNS = yolo2msghub motion2mqtt
SETUP = setup

ALL = $(BASES) $(SERVICES) $(PATTERNS)

##
## targets
##

TARGETS = all build push check test run stop remove clean distclean service-build service-push service-publish service-verify service-start service-test service-stop service-clean

## actual

default: $(ALL)

$(ALL):
	@echo ">>> MAKE -- making $@"
	@$(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) -C $@

$(TARGETS):
	@echo ">>> MAKE -- making $@ in ${ALL}"
	@for dir in $(ALL); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) -C $$dir $@; \
	done

pattern-publish:
	@echo ">>> MAKE -- publishing $(PATTERNS)"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) -C $$dir $@; \
	done

pattern-validate: 
	@echo ">>> MAKE -- validating $(PATTERNS)"
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) URL=$(URL) HZN_ORG_ID=$(HZN_ORG_ID) DOCKER_HUB_ID=$(DOCKER_HUB_ID) -C $$dir $@; \
	done

.PHONY: $(SERVICES) $(PATTERNS) default all build run check stop push publish verify clean start test sync cloc

sync: ../ibm/open-horizon .gitignore cloc 
	@echo ">>> MAKE -- synching ${ALL}"
	@rsync -av makefile service.makefile *.md *.sh .gitignore .travis.yml ../ibm/open-horizon
	@for dir in $(ALL) ${SETUP}; do \
	  rsync -a --info=name --exclude='service.json' --exclude='userinput.json' --exclude='pattern.json' --exclude-from=./.gitignore $${dir} ../ibm/open-horizon/ ; \
	done
	
cloc: .gitignore
	@echo ">>> MAKE -- counting source code"
	@cloc --md --exclude-list-file=.gitignore . > CLOC.md
