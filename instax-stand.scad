include <lib/BOSL2/std.scad>
include <lib/add-base.scad>
include <lib/fasteners.scad>

Add_base = false;
Part = "All"; // [All]

Slop = 0.15;

// Max thickness of the stand
Max_thickness = 19.6;

// thickness on the top
Min_thickness = 14.4;

// The amount the stand covers the case
Stand_inset = 5;

// How far this lifts the frame off the floor. Also decides the bottom thickness.
Height_off_floor = 3;

// How far the stand should extend out on each side
Stand_offset = 8;

Stand_thickness = 65;

// Distance between the two mounting screws in the back
Screw_offset = 50;

// The height of the M2 nuts you have
M2_nut_height = 1.6;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

Instax_wide_frame_dimensions = [113, 90];

module instax_wide_case(anchor=CENTER, spin=0, orient=TOP) {
    size = [Instax_wide_frame_dimensions.x, Max_thickness, Instax_wide_frame_dimensions.y];

    rounding=size.x/4;

    module _part() {
        prismoid(size1=[size.x, Max_thickness], size2=[size.x, Min_thickness], shift=[0, Max_thickness-Min_thickness], h=size.z, anchor=CENTER);
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}
module part(anchor=CENTER, spin=0, orient=TOP) {
    size = [Stand_thickness, Max_thickness + 2*Stand_offset, Stand_inset+Height_off_floor];

    rounding=Height_off_floor;

    module _part() {
        // TODO: nut pocket on both sides to keep it up? or maybe 2 parts to
        //       claim the whole thing (needs a middle piece too), but how is it
        //       even possible to make it printable?
        // TODO: how do we ensure Height_off_floor is consistent while printing?
        //       Print with the x-dimension on the bottom?
        // TODO: adjustable angle?
        // TODO: maybe a two piece that attaches to the slots on the back?
        diff(neg="neg")
            prismoid(size1=[size.x, size.y], size2=[size.x, Max_thickness+2*Stand_offset], h=size.z, rounding=rounding, anchor=CENTER) {
                position(TOP) up($eps)
                // cut out the middle part for the stasnd
                tags("neg") cuboid([size.x+2*$eps, Max_thickness, Stand_inset], anchor=TOP) {
                    // Round off allt he rough edges
                    mirror_copy(LEFT) position(BOTTOM+LEFT)
                        rounding_mask_y(r=rounding/4, l=Max_thickness);
                    mirror_copy(FRONT) position(TOP+FRONT)
                        rounding_mask_x(r=rounding/4, l=size.x+2*$eps);
                };
                tags("neg") position(BACK) mirror_copy(LEFT) left(Screw_offset/2) {
                    fwd(Stand_offset / 2) m2_hole(h=size.y);
                    hull() {
                        move_copies([CENTER, FRONT*Stand_offset/2])
                            m2_nut(h=M2_nut_height+Slop, taper=Slop);
                }
        }

        }
    }
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

anchor = BOTTOM;

add_base(enable=Add_base)
if (Part == "All") {
    part(anchor=anchor);
    if ($preview) {
       color("green", alpha=0.2) up(Height_off_floor) instax_wide_case(anchor=BOTTOM);
    }
}

$export_suffix = str(Part, "-take1");
