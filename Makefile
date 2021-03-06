default: help

render:
	mkdir -p output/
	mkdir -p output/$(gtfs)/
	touch output/$(gtfs)/data.lines
	time node render.js --verbose --gtfs=$(gtfs) --size=$(size);

clean:
	rm -r ouptut/

route-types:
	cat ./gtfs/$(gtfs)/routes.txt | awk -F "\"*,\"*" '{print $$5}' | uniq

help:
	echo "Use `$ make render gtfs=ulm` to start the process."

compare:
	cat output/ulm/maxmin.lines 
	cat output/madrid/maxmin.lines 
	cat output/los-angeles/maxmin.lines
	cat output/washington-dc/maxmin.lines
