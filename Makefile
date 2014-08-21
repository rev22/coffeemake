COFFEE=coffee

lib/%.js: src/%.coffee
	$(COFFEE) -pc $< >$@

all: lib/coffeemake.js
