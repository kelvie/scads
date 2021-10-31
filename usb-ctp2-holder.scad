include <lib/BOSL2/std.scad>
include <lib/add-base.scad>
include <lib/fasteners.scad>
include <lib/text.scad>

// Holder for the CTP2 DC quick charter buck adapters you can get cheap from
// China.

/* [General] */

// Only active with $preview
Add_base = true;
Part = "All"; // [Top, Bottom, All]
// Just for "All"
Explode_parts = 3; // [0:1:10]

Side_wall_thickness = 5.5;
Front_wall_thickness = 1;
Back_wall_thickness = 6;
Rounding = 3;

Back_label = "24V";

// Add some through holes in the back for wiring up the modules together
Wire_through_holes = true;

// Minimum wall (primarily used for the back set-screw)
Min_wall_thickness = 1;

// Height of the M2 nuts you have
Nut_hole_height = 1.6;
Slop = 0.15;

/* [Bottom] */

Bottom_wall_thickness = 1;
Bottom_component_clearance = 3.5;

// [x, z, rounding] -- z doesn't include pcb
Bottom_front_cutout = [9, 3.8, 1];
// [x, z, rounding] -- mirrored left and right
Bottom_back_side_cutout = [4, 1, 1];

// [x size, y size]
Bottom_front_side_standoffs = [3.5, 2];

// list of [x size, y size, y offset (center)]
Bottom_right_standoffs = [[3.5, 10, 25]];
Bottom_left_standoffs = [[2, 3, 30]];

// List of [x size, y size, x offset (from left side)]
Bottom_back_standoffs = [[3, 2, 11.7]];

/* [Top] */
Top_wall_thickness = 1;
Top_component_clearance = 9;

// [x, z, rounding]
Top_front_cutout = [14, 7, 0.15];

// [x, z, rounding] -- mirrored left and right
Top_back_side_cutout = [4, 2, 1];

// [x size, y size]
Top_front_side_standoffs = [1.5, 10];

// list of [x size, y size, y offset (center)]
Top_right_standoffs = [[5.5, 6, 16], [2, 2, 41]];
Top_left_standoffs = [[5.5, 6, 16], [2, 2, 41]];

// List of [x size, y size, x offset (from left side)]
Top_back_standoffs = [];

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

rounding = Rounding;


// Inches to mm
pcbsize = [18.24, 49.3, 1.2];

// Specs are [x, z, rounding]
module _cutout(specs, anchor, t=Front_wall_thickness, top_taper=0) {
    cutsize = [specs[0], t + 2*$eps, specs[1]] + Slop*[2, 2, 0];
    round_edges = top_taper > 0 ? "ALL" : BOTTOM;
    cuboid(cutsize, anchor=anchor, rounding=specs[2], edges=edges(round_edges, except=[FRONT, BACK])) {
    // Taper top to allow horizontal printing
        if (top_taper > 0) {
            position(TOP)
                down($eps)
                prismoid(size1=[cutsize.x - 2*specs[2], cutsize.y], size2=[0, cutsize.y], h=top_taper+$eps, anchor=BOTTOM);

        }
    }
}

module _pcb_standoff(size, anchor, h=Bottom_component_clearance) {
    rounding = min(size.x, size.y) / 4;
    up(Bottom_wall_thickness - $eps)
        cuboid([size.x, size.y, h + $eps], anchor=anchor,
               rounding=rounding, edges=edges("ALL", except=[TOP, BOTTOM, [anchor.x, 0, 0], [0, anchor.y, 0]]));

}

module _screw_holes(size, connector_type, spacing, flip=false) {
    // M2 screw holes on side rails
    if (Side_wall_thickness >= 5) {
        fwd((Back_wall_thickness - Front_wall_thickness)/2)
            mirror_copy(RIGHT) tags("neg") {
            left(Side_wall_thickness / 2) position(RIGHT) attach(BOTTOM) {
                fwd(spacing) {
                    if (connector_type == "bottom") {
                        up($eps) m2_nut(h=size.z - 2, anchor=TOP, slop=Slop);
                    } else if (connector_type == "side-slot") {
                        down(size.z - 2) hull() {
                            m2_nut(h=Nut_hole_height + Slop,
                                   anchor=flip ? TOP : BOTTOM,
                                   orient=flip ? BOTTOM : TOP,
                                   slop=Slop);

                            // This has 4x the slop to make them easier to insert.
                            left(Side_wall_thickness/2)
                                m2_nut(h=Nut_hole_height + Slop,
                                       anchor=flip ? TOP : BOTTOM,
                                       orient=flip ? BOTTOM : TOP,
                                       slop=4*Slop);
                        }
                    }
                    up($eps) m2_hole(h=size.z+2*$eps, anchor=TOP, taper=0.4);
                }
            }
        }
    }
}

module _double_screw_holes(size, invert=false) {
    // This uses pcbsize cause I thought I could adjust the wall thicknesses
    // and keep the same screw layouts, but the mirror(BACK) messes that up
    move_copies([CENTER, pcbsize.y / 2 * BACK]) {
        _screw_holes(size, invert ? "bottom" : "side-slot", pcbsize.y/9);
        mirror(UP) _screw_holes(size, invert ? "side-slot": "bottom", pcbsize.y/3, flip=invert);
    }
}

module _back_nut_holder() {
    position(BACK+TOP)
        fwd(Back_wall_thickness-Min_wall_thickness)
        xrot(90) {
        m2_nut(h=Nut_hole_height + Slop, anchor=TOP, spin=360/6/2, slop=Slop, taper=0);

        down(Min_wall_thickness+ Nut_hole_height + Slop)
            m2_nut(h=Back_wall_thickness, anchor=TOP, spin=360/6/2, slop=Slop, taper=0);

        // Withuot this hull, the screw hole creates a little hook that'll just
        // break off anyway.
        hull()
            move_copies([CENTER, 1*BACK])
            m2_hole(h=Back_wall_thickness+$eps);
    }
}

outer_size = [pcbsize.x + 2*Side_wall_thickness,
              pcbsize.y + Front_wall_thickness + Back_wall_thickness,
              0];

module _outer_part(size, edges, anchor=CENTER, spin=0, orient=TOP) {
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        intersection() {
            cuboid([size.x, size.y, size.z], rounding=rounding, edges=edges);
            // cuboid([size.x, size.y, size.z], chamfer=rounding/8, edges=edges(BOTTOM));
        }
        children();
    }

}

module _wire_through_hole(h, taper=1) {
    d = max(Top_back_side_cutout[0], Bottom_back_side_cutout[0]) + 2*Slop;
    if (Wire_through_holes)
       tags("neg") mirror_copy(LEFT) position(BACK+RIGHT)
            left(Side_wall_thickness)
            fwd(Back_wall_thickness/2 - $eps)
            cuboid([d, Back_wall_thickness /2+$eps, h+$eps], anchor=FRONT+RIGHT, rounding=Top_back_side_cutout[2], edges=edges("ALL", except=[TOP, BOTTOM, BACK])) {
        }
}

module bottom_part(anchor=CENTER, spin=0, orient=TOP,
                   edges=edges("ALL", except=[TOP,BOTTOM]),
                   connector="bottom",
                   bottom_wall=Bottom_wall_thickness) {
    extra_z = Bottom_component_clearance + bottom_wall + pcbsize.z + Slop;
    size = outer_size + extra_z * [0, 0, 1];

    module _part() {
        diff("neg", keep="keep") {
            // Like we're milling it, let's start with the main block and cut
            // shit out of it.
            _outer_part(size, edges) {

                // Cut out PCB
                position(TOP)
                    up($eps)
                    fwd((Back_wall_thickness - Front_wall_thickness)/2)
                    cuboid(pcbsize + Slop * [2, 2, 1], anchor=TOP, $tags="neg");

                // cut out space for PCB components
                position(TOP)
                    down(pcbsize.z)
                    up($eps)
                    fwd((Back_wall_thickness - Front_wall_thickness)/2)
                    cuboid([pcbsize.x, pcbsize.y, Bottom_component_clearance + $eps],  anchor=TOP, $tags="neg");

                // cut out bottom front connector
                position(FRONT + TOP)
                    fwd($eps)
                    down(pcbsize.z)
                    _cutout(Bottom_front_cutout, anchor=TOP+FRONT, top_taper=0.2, $tags="neg");

                // Cut out bottom back connector (right and left)
                mirror_copy(LEFT) position(BACK + TOP + RIGHT)
                    up($eps)
                    back($eps)
                    left(Side_wall_thickness)
                    _cutout(Bottom_back_side_cutout + pcbsize.z * [0, 1, 0], anchor=BACK+TOP+RIGHT, t=Back_wall_thickness, $tags="neg");

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
                            _pcb_standoff(spec, anchor=BOTTOM+LEFT, $tags="keep");
                    }

                position(BOTTOM+FRONT+RIGHT)
                    left(Side_wall_thickness)
                    back(Front_wall_thickness)
                    for (spec = Bottom_right_standoffs) {
                        back(spec[2])
                            _pcb_standoff(spec, anchor=BOTTOM+RIGHT, $tags="keep");
                    }

                position(BOTTOM+BACK+RIGHT)
                    left(Side_wall_thickness)
                    fwd(Back_wall_thickness)
                    for (spec = Bottom_back_standoffs) {
                        left(spec[2])
                            _pcb_standoff(spec, anchor=BOTTOM+BACK+RIGHT, $tags="keep");
                    }

                _double_screw_holes(size);

                _wire_through_hole(h=size.z);

                tags("neg")
                    down(pcbsize.z/2) _back_nut_holder();
            }
        }
    }
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

// Attach using the sides for unlimited stacking? Split bottom and top?
module middle_part(anchor=CENTER, spin=0, orient=TOP) {
    shared_wall = max(Bottom_wall_thickness, Top_wall_thickness);
    extra_z = Top_component_clearance + shared_wall + Bottom_component_clearance + pcbsize.z + Slop;

    size = outer_size + extra_z * [0, 0, 1];

    module _part() {
        up(size.z / 2)
            bottom_part(anchor=TOP, edges=edges("ALL", except=[TOP, BOTTOM]), connector="side-slot");
        down(size.z / 2)
            top_part(anchor=TOP, orient=BOTTOM, edges=edges("ALL", except=[TOP, BOTTOM]), connector="side-slot");
    }
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}


module top_part(anchor=CENTER, spin=0, orient=TOP,
                edges=edges("ALL", except=[TOP,BOTTOM]),
                connector="bottom",
                bottom_wall=Top_wall_thickness) {
    extra_z = Top_component_clearance + bottom_wall;
    size = outer_size + extra_z * [0, 0, 1];

    module _pcb_standoff_top(size, anchor) {
        _pcb_standoff(size=size, anchor=anchor, h=Top_component_clearance);
    }

    module _part() {
        diff("neg", keep="keep") {
            // Like we're milling it, let's start with the main block and cut
            // shit out of it.
            _outer_part(size, edges) {

                attach(BACK)
                    label(Back_label, spin=180);


                // Cut out part for pcb components
                position(TOP)
                    up($eps)
                    fwd((Back_wall_thickness - Front_wall_thickness)/2)
                    cuboid([pcbsize.x, pcbsize.y, 0] + Top_component_clearance * [0, 0, 1], anchor=TOP, $tags="neg");

                // cut out bottom front connector
                position(FRONT + TOP)
                    up($eps)
                    fwd($eps)
                    _cutout(Top_front_cutout, anchor=TOP+FRONT, $tags="neg");

                // Cut out bottom back connector (right and left)
                mirror_copy(LEFT) position(BACK + TOP + RIGHT)
                    up($eps)
                    back($eps)
                    left(Side_wall_thickness)
                    _cutout(Top_back_side_cutout, anchor=BACK+TOP+RIGHT, t=Back_wall_thickness, $tags="neg");

                _wire_through_hole(h=size.z);

                // Various standoffs
                mirror_copy(LEFT)
                position(BOTTOM+FRONT+RIGHT)
                    left(Side_wall_thickness)
                    back(Front_wall_thickness)
                    _pcb_standoff_top(Top_front_side_standoffs, anchor=BOTTOM+FRONT+RIGHT, $tags="keep");

                position(BOTTOM+FRONT+LEFT)
                    right(Side_wall_thickness)
                    back(Front_wall_thickness)
                    for (spec = Top_left_standoffs) {
                        back(spec[2])
                            _pcb_standoff_top(spec, anchor=BOTTOM+LEFT, $tags="keep");
                    }

                position(BOTTOM+FRONT+RIGHT)
                    left(Side_wall_thickness)
                    back(Front_wall_thickness)
                    for (spec = Top_right_standoffs) {
                        back(spec[2])
                            _pcb_standoff_top(spec, anchor=BOTTOM+RIGHT, $tags="keep");
                    }

                position(BOTTOM+BACK+RIGHT)
                    left(Side_wall_thickness)
                    fwd(Back_wall_thickness)
                    for (spec = Top_back_standoffs) {
                        left(spec[2])
                            _pcb_standoff_top(spec, anchor=BOTTOM+BACK+RIGHT, $tags="keep");
                    }

                _double_screw_holes(size, invert=true);

                tags("neg")
                    up(pcbsize.z/2) _back_nut_holder();
            }
        }
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

anchor = (Add_base && !$preview) ? BOTTOM : CENTER;

add_base(enable=Add_base && !$preview)
if (Part == "Top") {
    top_part(anchor=anchor, orient=TOP);
} else if (Part == "Middle") {
    middle_part(anchor=anchor);
} else if (Part == "Bottom") {
    bottom_part(anchor=anchor);
} else {
    up(Explode_parts)
        color("red") top_part(anchor=TOP, orient=BOTTOM);
    down(Explode_parts)
        color("white") bottom_part(anchor=TOP, orient=TOP);
}

$export_suffix = str(Part, "-take8");
