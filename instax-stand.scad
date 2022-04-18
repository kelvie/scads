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

// Distance between the two cartridge slots
Cartridge_slot_offset = 50;

// The height between the bottom of the cartridge and the slot in the back
Cartridge_slot_height = 23.5;

// The size of the smaller slot in the back of the cartridge.
Cartridge_slot_size = 10.5;

Back_bump_offset = 2;

// The height of the M2 nuts you have
M2_nut_height = 1.6;

// 0 is straight up, more tilts back further
Tilt_angle = 10;

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
    size = [Stand_thickness, Max_thickness + 2*Stand_offset, Height_off_floor + Cartridge_slot_height + Cartridge_slot_size / 2];

    rotated_y = size.y * cos(Tilt_angle) + size.z * sin(Tilt_angle);
    rotated_z = size.y * sin(Tilt_angle) + size.z * cos(Tilt_angle);
    rotated_size = [size.x, rotated_y, rotated_z];

    rounding=Height_off_floor;

    module _part() {
        // TODO: nut pocket on both sides to keep it up? or maybe 2 parts to
        //       claim the whole thing (needs a middle piece too), but how is it
        //       even possible to make it printable?
        // TODO: how do we ensure Height_off_floor is consistent while printing?
        //       Print with the x-dimension on the bottom?
        // TODO: maybe a two piece that attaches to the slots on the back?
        diff(neg="neg")
            down(size.z / 2) prismoid(size1=[size.x, size.y], size2=[size.x, Max_thickness+2*Stand_offset],
                                      h=Height_off_floor + Stand_inset, rounding=rounding, anchor=BOTTOM) {
                position(TOP) up($eps)
                // cut out the middle part for the stasnd
                tags("neg") cuboid([size.x+2*$eps, Max_thickness, Stand_inset], anchor=TOP) {
                    // Round off allt he rough edges
                    mirror_copy(LEFT) position(BOTTOM+LEFT)
                        rounding_mask_y(r=rounding/4, l=Max_thickness);
                    position(TOP+FRONT)
                        rounding_mask_x(r=rounding/4, l=size.x+2*$eps);
                };

                // Add a bottom to the tilt
                if (Tilt_angle != 0)
                        position(BOTTOM) up($eps)
                            cuboid([size.x, size.y, size.z], anchor=TOP, rounding=rounding, edges=edges("ALL", except=[TOP, BOTTOM]));

                // Make two pillars in the back to hold up the cartridge (and insert into the slot)
                // TODO: how does this keep the cartridge from flippping over? it doesn't seem to.
                // Front flaps? then the back at least secures movement in the X direction.
                // Why not just 2 triangles then?
                position(TOP) position(BACK) mirror_copy(LEFT) left(Cartridge_slot_offset/2)
                    cuboid([Cartridge_slot_size, Stand_offset, Cartridge_slot_height + Cartridge_slot_size / 2 - Stand_inset],
                           anchor=BOTTOM+BACK, rounding=rounding/2, edges=edges("ALL", except=[BOTTOM])) {
                    position(TOP+BACK)
                        cuboid([Cartridge_slot_size, Back_bump_offset + Stand_offset, Cartridge_slot_size], anchor=TOP+BACK,
                               rounding=rounding/2);
                }
        }

    }

    attachable(size=rotated_size, anchor=anchor, spin=spin, orient=orient) {
        // Cut off the excess, but leave the front bit
        intersection() {
            xrot(-Tilt_angle) _part();
            cuboid(rotated_size + [0, size.y, 0]);
        }

        children();
    }
}

anchor = BOTTOM;

add_base(enable=Add_base)
if (Part == "All") {
    part(anchor=CENTER);
    if ($preview) {
       // color("green", alpha=0.2) up(Height_off_floor) instax_wide_case(anchor=BOTTOM);
    }
}

$export_suffix = str(Part, "-take1");
