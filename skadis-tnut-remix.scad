// A rewrite of https://www.printables.com/model/228663-t-nuts-for-ikea-skadis-pegboards
//
// Added features: press-in nut that can handle being screwd in and out
// Chamfered base to avoid elephants foot

include <lib/BOSL2/std.scad>
include <lib/add-base.scad>
include <lib/fasteners.scad>

Add_base = true;
Part = "All"; // [All]
Base_height = 4;

Slop = 0.15;

// For add_base, amount to inset
Base_inset = 0.3;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

top_extrusion = 4;
outer_sz = [4.7, 10, top_extrusion+Base_height];
rounding = 0.75;


module part(anchor=CENTER, spin=0, orient=TOP) {
    size = outer_sz;

    module _part() {
        // Use top-level cuboid for positioning only

        show_only("visible") cuboid(size) tag("visible") {
            difference() {
                union() {
                    position(BOTTOM) cuboid([outer_sz.x, outer_sz.y, Base_height], anchor=BOTTOM, rounding=rounding);

                    cyl(d=outer_sz.x, h=outer_sz.z, rounding=rounding);

                    mirror_copy(LEFT+BACK) position(TOP) left(outer_sz.x / 2) back(outer_sz.x / 2)
                        cuboid([outer_sz.x/2,  outer_sz.x / 2, outer_sz.z/4*3], anchor=LEFT+BACK+TOP, rounding=rounding, edges=TOP+BACK+LEFT);
                }
                // Allow insertion from the left
                position(BOTTOM) hull() move_copies([CENTER, 2.9*RIGHT]) zrot(360 / 6/2) up(Base_height / 2)  m2dot5_nut(h=2, orient=BOTTOM);
                zcyl(d=2.9, h=outer_sz.z + 2*$eps, anchor=CENTER);
            }


        }
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

// add_base = !$preview && Add_base;
add_base = Add_base;
anchor = Add_base ? BOTTOM : CENTER;

add_base(enable=add_base, inset=Base_inset)
if (Part == "All") {
    part(anchor=anchor);
}

$export_suffix = str(Part, "-take1");
