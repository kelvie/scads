include <lib/BOSL2/std.scad>
include <lib/BOSL2/hull.scad>

include <lib/add-base.scad>
include <lib/fasteners.scad>

// Includes the walls
PSU_height = 37;
// Also includes the walls
PSU_width = 89;

// Distance from the middle of the terminal entry point to the bottom of the PSU
Terminal_height_from_bottom = 15.5;
// Height of the slot -- the entire connector needs to be able to slot through this
Terminal_slot_height = 6;
// The offset from the terminal block to the side of the PSU, or less.
Terminal_slot_side_wall_left = 10; // [10, 8]
Terminal_slot_side_wall_right = 50; // [50, 8]

Screw_distance_from_front_left = 20.5; // [20.5, 22.0]
Screw_distance_from_front_right = 6.0; // [6.0, 22]
Screw_distance_from_top = 4.5;

Wall_thickness = 2;

Tolerance = 0.1;

Add_base = true;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/2;

wt = Wall_thickness;

module part(anchor=CENTER, spin=0, orient=TOP) {
    // Always want to be double the max screw length wide so this doesn't twist
    // while screwing it in/out
    depth = 2*max(Screw_distance_from_front_right, Screw_distance_from_front_left);
    psu_size = [PSU_width, depth, PSU_height]
        + Tolerance*[2, 1, 1];
    size =  psu_size + wt*[2, 1, 1];

    module _part() {
        diff("cutme")
            cuboid(size, rounding=wt) {
            position(BACK+BOTTOM)
                down($eps) back($eps) cuboid(psu_size + $eps*[0, 1, 1],
                                  $tags="cutme", anchor=BACK+BOTTOM) {

                // Size checks
                % position(BOTTOM)
                    cuboid([psu_size.x, 10, Terminal_height_from_bottom],
                           anchor=BOTTOM);

                % position(FRONT+TOP) down(Screw_distance_from_top) {
                    back(Screw_distance_from_front_left)
                        left(psu_size.x/2) xcyl(d=3, h=psu_size.x/4);

                    back(Screw_distance_from_front_right)
                        right(psu_size.x/2) xcyl(d=3, h=psu_size.x/4);
                }
            }

            // Slot
            slot_width = psu_size.x - Terminal_slot_side_wall_left - Terminal_slot_side_wall_right;
            position(BOTTOM+FRONT+LEFT) {
                up(Tolerance+Terminal_height_from_bottom)
                    right(Terminal_slot_side_wall_left)
                    fwd($eps)
                    prismoid(size1=[slot_width + wt, Terminal_slot_height + wt],
                             size2=[slot_width, Terminal_slot_height],
                             h=wt+2*$eps,
                             rounding=wt/2,
                             orient=BACK,
                             anchor=BOTTOM+LEFT, $tags="cutme");
            }

            position(LEFT+TOP+FRONT)
                down(Screw_distance_from_top + wt + Tolerance)
                back(Screw_distance_from_front_left + wt + Tolerance) {
                m3_screw_rail(l=0, h=2*wt, $tags="cutme", orient=LEFT);
            }
            position(RIGHT+TOP+FRONT)
                down(Screw_distance_from_top + wt + Tolerance)
                back(Screw_distance_from_front_right + wt + Tolerance) {
                m3_screw_rail(l=0, h=2*wt, $tags="cutme", orient=RIGHT);
            }
        }
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

add_base(enable=!$preview && Add_base)
part(orient=FRONT, anchor=FRONT);

$export_suffix = str(Screw_distance_from_front_left, "mm-screw-offset");
