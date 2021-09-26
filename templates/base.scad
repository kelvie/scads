include <lib/BOSL2/std.scad>

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

module part(anchor=CENTER, spin=0, orient=TOP) {
    size = [1, 1, 1];

    module _part() {
        cuboid(size);
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

part();
