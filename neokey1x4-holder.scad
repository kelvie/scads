include <lib/BOSL2/std.scad>
include <lib/add-base.scad>

Add_base = false;
Part = "Top"; // [Top, Bottom, All]

// Total thickness (z-direction) -- should probably be the screw (thread) length
Thickness = 8;
Screw_length = 12;

// How far into the PCB should the side wall extend
Side_wall_xoffset = 3;

// How far the tallest bottom component on the pcb extends to
Bottom_component_clearance = 3;

// x-dimension thickness of side wall
Side_wall_thickness = 5;
Front_wall_thickness = 1.5;

Slop = 0.15;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;


// Inches to mm
pcbsize = 25.4 * [0.85, 3.0, 0] + [0, 0, 2];
hole_spacing = 25.4 * [0.65, 1.5, 0];
screw_hole_d = 2.9;
screw_size = 2.5;
rounding = 0.25;

// From the side of the PCB
connector_cutout_width = 12;

// Unused I think
nut_size_across_corners = 5.77;
nut_size_across_flats = 5;
nut_height = 2;

// 3/4" spacing between keys
key_spacing = 0.75 * 25.4;

cherry_switch_hole_size = 14;
cherry_key_height = 5;

module bottom_part(anchor=CENTER, spin=0, orient=TOP) {
    size = [pcbsize.x + 2*Side_wall_thickness - 2*Side_wall_xoffset,
            pcbsize.y + 2*Front_wall_thickness,
            Thickness];

    module _outer_part(anchor=CENTER, spin=0, orient=TOP) {
        attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
            diff("neg") {
                cuboid([size.x, size.y, size.z], rounding=rounding, edges=edges("ALL", except=TOP))
                    position(TOP)
                    cuboid([pcbsize.x - 2*Side_wall_xoffset, pcbsize.y, pcbsize.z + Bottom_component_clearance] + Slop * [2, 2, 1], anchor=TOP, $tags="neg");
            }
            children();
        }

    }
    module _part() {
        diff("neg", keep="keep") {
            // Like we're milling it, let's start with the main block and cut
            // shit out of it.
            _outer_part() {

                // Cut out PCB
                position(TOP)
                    up($eps)
                    cuboid(pcbsize + Slop * [2, 2, 1], anchor=TOP, $tags="neg");

                // Cut out portion for connectors
                mirror_copy(FRONT) position(FRONT+TOP)
                    left(pcbsize.x/2 +  Slop)
                    fwd($eps)
                    up($eps)
                    cuboid([connector_cutout_width + Slop,
                            Front_wall_thickness + 2*$eps - Slop,
                            Bottom_component_clearance + pcbsize.z + Slop+ $eps],
                           anchor=FRONT+TOP+LEFT, $tags="neg");
            }

            mirror_copy(LEFT) move_copies([-hole_spacing / 2, hole_spacing / 2]) {
                // Cut out screw hole
                cyl(d=screw_hole_d, h = 2*Thickness, $tags="neg");
                // Cut out nut hole on bottom
                position(BOTTOM) down($eps)
                    cyl(d1=nut_size_across_corners+1, d2=nut_size_across_corners, h=nut_height+Slop, anchor=BOTTOM, $tags="neg", $fn=6);
            }

            /* // Nubs to go into the PCB screw hole (to save screws) */
            /* mirror(LEFT) move_copies([-hole_spacing / 2, hole_spacing / 2])  { */
            /*     // Cut out screw hole */
            /*     cyl(d=screw_size, h = size.z, chamfer2=screw_size/4, $tags="keep"); */
            /* } */

            // Pillars to surround the screw
            mirror_copy(LEFT) move_copies([-hole_spacing / 2, hole_spacing / 2]) {
                cyl(d=nut_size_across_corners, h =size.z);
            }
        }
    }
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

// TODO: don't have screws this long, need to attach another way
module top_part(anchor=CENTER, spin=0, orient=TOP) {
    size = [pcbsize.x + 2*Side_wall_thickness - 2*Side_wall_xoffset,
            pcbsize.y + 2*Front_wall_thickness,
            cherry_key_height];

    module _part() {
        diff("neg", keep="keep") {
            cuboid(size, rounding=rounding, edges=edges("ALL", except=TOP)) {
                ycopies(spacing=key_spacing, 4)
                    cuboid([cherry_switch_hole_size, cherry_switch_hole_size, size.z+2*$eps], $tags="neg");
            }

            screw_head_hole_depth = cherry_key_height + Thickness - Screw_length;
            mirror_copy(LEFT) move_copies([-hole_spacing / 2, hole_spacing / 2]) {
                // Cut out screw hole
                cyl(d=screw_hole_d, h = 2*Thickness, $tags="neg");
                // Cut out nut hole on bottom
                position(BOTTOM) down($eps)
                    cyl(d1=nut_size_across_corners+0.5, d2=nut_size_across_corners, h=screw_head_hole_depth+Slop, anchor=BOTTOM, $tags="neg", $fn=6);
            }
        }
    }
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

anchor = Add_base ? BOTTOM : CENTER;

add_base(enable=Add_base)
if (Part == "Top")
    top_part(anchor=anchor* -1, orient=BOTTOM);
else if (Part == "Bottom")
    bottom_part(anchor=anchor);
else {
    top_part(anchor=TOP, orient=BOTTOM);
    color("green") bottom_part(anchor=TOP);
}
