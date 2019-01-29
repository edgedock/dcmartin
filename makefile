## ORG
ORG = dcmartin@us.ibm.com

SERVICES = cpu hal wan yolo
PATTTERNS = yolo2msghub motion

default: $(SERVICES)

all: $(SERVICES) $(PATTERNS)

$(PATTERNS):
	$(MAKE) ORG=$(ORG) -C $@

$(SERVICES):
	$(MAKE) ORG=$(ORG) -C $@

build:
	for dir in $(SERVICES); do \
	  $(MAKE) -C $$dir $@; \
	done

remove:
	for dir in $(SERVICES); do \
	  $(MAKE) -C $$dir $@; \
	done


clean:
	for dir in $(SERVICES); do \
	  $(MAKE) -C $$dir $@; \
	done

publish:
	for dir in $(SERVICES); do \
	  $(MAKE) ORG=$(ORG) -C $$dir $@; \
	done

verify:
	for dir in $(SERVICES); do \
	  $(MAKE) ORG=$(ORG) -C $$dir $@; \
	done

.PHONY: $(SERVICES) $(PATTERNS) default all build run check stop push publish verify clean depend start
