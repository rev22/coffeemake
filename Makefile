COFFEE=coffee

lib/%.js: src/%.coffee
	$(COFFEE) -pc $< >$@
