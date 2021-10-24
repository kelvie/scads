include <lib/BOSL2/std.scad>
include <lib/add-base.scad>

Add_base = false;
Part = "All"; // [All]

Slop = 0.15;

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

anchor = Add_base ? BOTTOM : CENTER;

add_base(enable=Add_base)
if (Part == "All") {
    part(anchor=anchor);
}

$export_suffix = str(Part, "-take1");
