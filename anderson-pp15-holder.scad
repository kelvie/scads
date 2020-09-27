include <lib/BOSL2/std.scad>

include <lib/anderson-connectors.scad> // pp15_casing
include <lib/add-base.scad> // add_base
use <lib/text.scad>

// Whether or not to engrave the tolerance on the part (mainly used for testing)
Print_tolerance = false;

Show_mask = false;

Part_to_show = "Multi-holder"; // [Casing, Base, Mask, Multi-holder, Multi-holder casing, All]
Legs = "RIGHT"; // [BOTH, LEFT, RIGHT, NONE]
Add_base = true;

Debug_shapes = false;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

module changeDirection(direction=Dovetail_direction) {
    if (direction == 2)
        mirror(LEFT) children(0);
    else
        children(0);
}

module show_part() {
    part = Part_to_show;
    if (part == "Base") {
        pp15_base_plate();
    } else if (part == "All") {
        pp15_base_plate(anchor=TOP);
        pp15_casing(anchor=TOP);
        % pp15_casing(anchor=TOP, mask=3);
        % pp15_casing_wirehider_mask(3, anchor=TOP);
    } else if (part == "Mask") {
        pp15_casing(anchor=TOP, mask=3);
    } else if (part == "Casing") {
        pp15_casing(anchor=TOP, wirehider=Wire_hider, legs=Legs);
    } else if (part == "Multi-holder casing") {
        add_base(enable=Add_base, zcut=0.2)
            pp15_casing(orient=TOP, wirehider=false,
                        legs="RIGHT",
                        spin=180, wall=2, rounding=2/2, anchor=BOTTOM);
    } else if (part== "Multi-holder") {
        add_base(enable=Add_base) union() {
            pp15_multi_holder(n=3, width=55, wall=2, anchor=BOTTOM);
            if (Debug_shapes)
                % fwd(10)
                      color("gray", alpha=0.2)
                      pp15_multi_holder_cutout(t=4, n=3, width=55, wall=2,
                                               anchor=BOTTOM);
        }
    }
}

show_part();
$export_suffix = Part_to_show;
