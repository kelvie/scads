
SCADS := $(wildcard *.scad)
PNGS := $(patsubst %.scad, png/%.png, $(SCADS))
INLINED := $(patsubst %.scad, build/%-inlined.scad, $(SCADS))

default: $(INLINED)

build/%-inlined.scad: %.scad
	mkdir -p build
	openscad -o $@ $^

%.deps: %.scad
	openscad -d $@ $< -o out.echo
	-rm out.echo

clean:
	rm -rf *.deps *-inlined.scad *.json build png

# obvs doesn't work for stl files, or nested includes, or files that have the
# word 'out.echo' in it
%-inlined.scad: %.deps %.scad
	cat $(shell tac $< | grep -v 'out.echo' | sed 's/\\//g') | grep -v -e '^\s*include\>' -e '^\s*use\>' > $@

png/%.png: %.scad
	mkdir -p png
	openscad -o $@ $^

pngs: $(PNGS)

wiki-gallery:
	scripts/make-gallery ../scads.wiki/Gallery.md
	cp -r png/ ../scads.wiki/
