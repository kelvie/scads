include <lib/BOSL2/std.scad>
include <lib/add-base.scad>
include <lib/fasteners.scad>

Add_base = false;
Part = "Bottom"; // [Top, Bottom, All]

Side_wall_thickness = 5.5;
Front_wall_thickness = 1;
Back_wall_thickness = 4;
Bottom_wall_thickness = 2;
Rounding = 0.25;

Bottom_component_clearance = 3.5;

// [x, z, rounding]
Bottom_front_cutout = [9, 3.3, 1];

// [x, z, rounding] -- mirrored left and right
Bottom_back_side_cutout = [4, 1, 1];

// [x size, y size]
Bottom_front_side_standoffs = [3.5, 2];

// list of [x size, y size, y offset (center)]
Bottom_right_standoffs = [[3.5, 10, 25]];
Bottom_left_standoffs = [[2, 3, 30]];

// List of [x size, y size, x offset (from left side)]
Bottom_back_standoffs = [[3, 2, 11.7]];

Slop = 0.15;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

rounding = Rounding;


// Inches to mm
pcbsize = [18.24, 49.3, 1.2];

// Specs are [x, z, rounding]
module _cutout(specs, anchor, t=Front_wall_thickness) {
    cutsize = [specs[0], t + 2*$eps, pcbsize.z + specs[1]] + Slop*[2, 2, 0];
    cuboid(cutsize, anchor=anchor, rounding=specs[2], edges=edges([BOTTOM], except=[FRONT, BACK]));
}

module _pcb_standoff(size, anchor) {
    cuboid([size.x, size.y, Bottom_component_clearance + Bottom_wall_thickness], anchor=anchor);

}

module bottom_part(anchor=CENTER, spin=0, orient=TOP) {
    size = [pcbsize.x + 2*Side_wall_thickness,
            pcbsize.y + Front_wall_thickness + Back_wall_thickness,
            pcbsize.z + Bottom_component_clearance + Bottom_wall_thickness];

    module _outer_part(anchor=CENTER, spin=0, orient=TOP) {
        attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
            cuboid([size.x, size.y, size.z], rounding=rounding, edges=edges("ALL", except=TOP));
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
                    fwd((Back_wall_thickness - Front_wall_thickness)/2)
                    cuboid(pcbsize + Slop * [2, 2, 1] + Bottom_component_clearance * [0, 0, 1], anchor=TOP, $tags="neg");

                // cut out bottom front connector
                position(FRONT + TOP)
                    up($eps)
                    fwd($eps)
                    _cutout(Bottom_front_cutout, anchor=TOP+FRONT, $tags="neg");

                // Cut out bottom back connector (right and left)
                mirror_copy(LEFT) position(BACK + TOP + RIGHT)
                    up($eps)
                    back($eps)
                    left(Side_wall_thickness)
                    _cutout(Bottom_back_side_cutout, anchor=BACK+TOP+RIGHT, t=Back_wall_thickness, $tags="neg");

                // Various standoffs
                mirror_copy(LEFT)
                position(BOTTOM+FRONT+RIGHT)
                    left(Side_wall_thickness)
                    back(Front_wall_thickness)
                    _pcb_standoff(Bottom_front_side_standoffs, anchor=BOTTOM+FRONT+RIGHT, $tags="keep");

                position(BOTTOM+FRONT+LEFT)
                    right(Side_wall_thickness)
                    back(Front_wall_thickness)
                    for (spec = Bottom_left_standoffs) {
                        back(spec[2])
                            _pcb_standoff(spec, anchor=BOTTOM+FRONT+LEFT, $tags="keep");
                    }

                position(BOTTOM+FRONT+RIGHT)
                    left(Side_wall_thickness)
                    back(Front_wall_thickness)
                    for (spec = Bottom_right_standoffs) {
                        back(spec[2])
                            _pcb_standoff(spec, anchor=BOTTOM+FRONT+RIGHT, $tags="keep");
                    }

                position(BOTTOM+BACK+RIGHT)
                    left(Side_wall_thickness)
                    fwd(Back_wall_thickness)
                    for (spec = Bottom_back_standoffs) {
                        left(spec[2])
                            _pcb_standoff(spec, anchor=BOTTOM+BACK+RIGHT, $tags="keep");
                    }

                // M2 screw holes on side rails -- make sure they are the same
                // position relative to the PCB size, so when I change other
                // parameters later, I can still fit the top and bottom pieces
                // together.
                if (Side_wall_thickness >= 5) {
                    fwd((Back_wall_thickness - Front_wall_thickness)/2)
                    mirror_copy(RIGHT) tags("neg") {
                        left(Side_wall_thickness / 2) position(RIGHT) attach(BOTTOM) {
                            mirror_copy(BACK)
                            fwd(pcbsize.y/4) {
                                up($eps) m2_nut(h=size.z-2, anchor=TOP);
                                up($eps) m2_hole(h=size.z+2*$eps, anchor=TOP);
                            }
                        }
                    }
                }
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
    size = [pcbsize.x + 2*Side_wall_thickness,
            pcbsize.y + 2*Front_wall_thickness,
            pcbsize.z ];

    module _part() {
        diff("neg", keep="keep") {
            cuboid(size, rounding=rounding, edges=edges("ALL", except=TOP));
        }
    }
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

anchor = Add_base ? BOTTOM : CENTER;

add_base(enable=Add_base)
if (Part == "Top") {
    $suffix="top";
    top_part(anchor=anchor* -1, orient=BOTTOM);
} else if (Part == "Bottom") {
    $suffix="bottom";
    bottom_part(anchor=anchor);
} else {
    top_part(anchor=TOP, orient=BOTTOM);
    color("green") bottom_part(anchor=TOP);
}

$export_suffix = str(Part, "-take1");
