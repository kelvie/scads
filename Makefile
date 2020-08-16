default: c-mount-rear-lens-cap-inlined.scad

SCADS := $(wildcard *.scad)
PNGS := $(patsubst %.scad, png/%.png, $(SCADS))

%.deps: %.scad
	openscad -d $@ $< -o out.echo
	-rm out.echo

clean:
	rm -f *.deps *-inlined.scad

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
