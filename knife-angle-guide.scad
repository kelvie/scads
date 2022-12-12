include <lib/BOSL2/std.scad>
include <lib/add-base.scad>
include <lib/text.scad>

Add_base = true;
Part = "All"; // [All]

Slop = 0.15;
Knife_angle = 15;
Width = 40;
Length = 50;

// For add_base, the minimum bottom thickness
Min_bottom_thickness = 4;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

// TODO: how to mount to the block, either have it on the side somehow? or take
// up some of the space by using a rbber band (in which case cut a groove for
// it)
//
// TODO: Make less sharp and prone to chipping (chop off the front and top bit)
module part(anchor=CENTER, spin=0, orient=TOP) {
    height = Length * tan(Knife_angle);
    size = [Width, Length, height];

    module _part() {
        diff("remove") cuboid(size, rounding=size.z / 8) {

            position(RIGHT+BOTTOM)
                tag("remove") yrot(Knife_angle) cuboid(2*size, anchor=RIGHT+BOTTOM);

            attach(LEFT)
                tag("remove") up($eps) label(str(Knife_angle, "°",), h=size.z/2, font="PragamataPro", anchor=TOP);
                }

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
