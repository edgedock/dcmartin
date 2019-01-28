## services
SERVICES = cpu hal wan yolo

default: all

all: $(SERVICES)

$(SERVICES):
	$(MAKE) -C $@

clean:
	for dir in $(SERVICES); do \
	  $(MAKE) -C $$dir; \
	done

.PHONY: $(SERVICES) default all build run check stop push publish verify clean depend start
