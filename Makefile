TARGETS := dist/assets/js/odyssey.js dist/assets/js/odyssey.min.js dist/assets/js/init.js manifester/world/cities.json manifester/world/trips.json dist/assets/world.json dist/assets/css/odyssey.css
seed := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)

.PHONY: clean build rebuild deploy

dist/assets/css/odyssey.css: src/odyssey.css
	crass src/odyssey.css --optimize > dist/assets/css/odyssey.css

dist/assets/js/odyssey.js:
	elm make src/Main.elm --output=dist/assets/js/odyssey.js --optimize

dist/assets/js/odyssey.min.js: dist/assets/js/odyssey.js
	uglifyjs dist/assets/js/odyssey.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=dist/assets/js/odyssey.min.js

prodjs: dist/assets/js/odyssey.min.js
	mv dist/assets/js/odyssey.min.js dist/assets/js/odyssey.${seed}.min.js

dist/assets/js/init.js: src/init.js vendor/d3.v3.min.js vendor/topojson.1.6.19.min.js
	uglifyjs vendor/d3.v3.min.js vendor/topojson.1.6.19.min.js src/init.js --output dist/assets/js/init.js

prodindex: dist/index.html
	sed -i 's/odyssey.*.js/odyssey.${seed}.min.js/' dist/index.html

debugindex: dist/index.html
	sed -i 's/odyssey.*.js/odyssey.js/' dist/index.html

build: dist/assets/js/odyssey.min.js prodindex dist/assets/css/odyssey.css
	@-rm -f dist/assets/js/odyssey.js

rebuild: clean build

manifest: manifester/odyssey.yaml manifester/world/cca3.json manifester/world/countries.json
	cd manifester; ./update_manifest.sh; cargo run --release; cd ..

serve: dist/assets/js/init.js debugindex dist/assets/css/odyssey.css
	elm-live src/Main.elm -d dist --pushstate --open -- --output=dist/assets/js/odyssey.js --optimize

debug: dist/assets/js/init.js debugindex dist/assets/css/odyssey.css
	elm-live src/Main.elm -d dist --pushstate --open -- --output=dist/assets/js/odyssey.js --debug

clean:
	@-rm -f $(TARGETS)

deploy: manifest prodindex dist/assets/js/init.js dist/assets/css/odyssey.css build prodjs
	rsync -avr --exclude='*.desc' --chown=www-data:www-data --checksum --delete -e ssh dist/ AkashaR:odyssey
