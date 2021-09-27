
include <lib/BOSL2/std.scad>


Thickness = 6;

// How far into the PCB should the side wall extend
Side_wall_xoffset = 3;
Side_wall_height = 4;

// x-dimension thickness of side wall
Side_wall_thickness = 5;
Front_wall_thickness = 2;

Slop = 0.1;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;


// Inches to mm
pcbsize = 25.4 * [0.85, 3.0, 0] + [0, 0, 2];
hole_spacing = 25.4 * [0.65, 1.5, 0];
screw_hole_d = 2.9;
rounding = 0.25;

// Unused I think
nut_size_across_corners = 5.77;
nut_size_across_flats = 5;
nut_height = 2;

module part(anchor=CENTER, spin=0, orient=TOP) {
    size = [pcbsize.x + 2*Side_wall_thickness - 2*Side_wall_xoffset,
            pcbsize.y + 2*Front_wall_thickness,
            Thickness];

    module _outer_part(anchor=CENTER, spin=0, orient=TOP) {
        attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
            diff("neg") {
                cuboid([size.x, size.y, size.z], rounding=rounding)
                    position(TOP)
                    cuboid([pcbsize.x - 2*Side_wall_xoffset, pcbsize.y, Side_wall_height], anchor=TOP, $tags="neg");
            }
            children();
        }

    }
    module _part() {
        diff("neg") {
            // Like we're milling it, let's start with the main block and cut
            // shit out of it.
            _outer_part() {

                // Cut out PCB
                position(TOP)
                    up($eps)
                    cuboid(pcbsize + Slop * [1, 1, 1], anchor=TOP, $tags="neg");

                // Cut out portion for connectors
                mirror_copy(FRONT) position(FRONT+TOP)
                    left(pcbsize.x/4)
                    fwd($eps)
                    up($eps)
                    cuboid([pcbsize.x/2,
                            Front_wall_thickness + 2*$eps,
                            Side_wall_height],
                           anchor=FRONT+TOP, $tags="neg");
            }

            // Cut out screw holes, and spacers, and nut holder
            mirror_copy(BACK) mirror_copy(LEFT)
                move(hole_spacing / 2) {
                cyl(d=screw_hole_d, h =2*Thickness, $tags="neg");
                cyl(d=nut_size_across_corners, h =size.z);
                position(BOTTOM) down($eps)
                    cyl(d1=nut_size_across_corners+1, d2=nut_size_across_corners, h=nut_height+Slop, anchor=BOTTOM, $tags="neg", $fn=6);
            }
        }
    }
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

part();
