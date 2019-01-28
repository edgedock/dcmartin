## ORG
ORG = dcmartin@us.ibm.com

## services
SERVICES = cpu hal wan yolo

default: all

all: $(SERVICES)

$(SERVICES):
	$(MAKE) ORG=$(ORG) -C $@

check:
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


.PHONY: $(SERVICES) default all build run check stop push publish verify clean depend start
