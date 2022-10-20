include <lib/BOSL2/std.scad>
include <lib/add-base.scad>

Add_base = true;
Part = "All"; // [All]

Slop = 0.15;

// For add_base, the minimum bottom thickness
Min_bottom_thickness = 4;

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

add_base = !$preview && Add_base;
anchor = add_base ? BOTTOM : CENTER;

// Make sure there's a base for features that are at least Min_bottom_thickness,
// with at least a thickness of 0.2
base_inset = min((Min_bottom_thickness) / 2 - 0.2, 1.5);
echo("Inset to remove elephant's foot is ", base_inset);

add_base(enable=add_base, inset=base_inset)
if (Part == "All") {
    part(anchor=anchor);
}

$export_suffix = str(Part, "-take1");
