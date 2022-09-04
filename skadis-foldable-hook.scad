// A backing to mount foldable clamps onto a SKADIS
//
// Or really for anything else
include <lib/BOSL2/std.scad>
include <lib/add-base.scad>

include <lib/skadis.scad>
Add_base = false;
Part = "All"; // [All]

Slop = 0.15;
// TODO: auto height
Height = 55;
Width = 25;
// TODO calculate thickness based on min thickness + nut height
Min_thickness = 2;

Hole_z_offset = 7;
Screw_size = 4;
Screw_hole_spacing = 22.5;

// Across widths (M4=7, M3=5.5, M2.5=5, M2=4)
Nut_width =  7;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

Screw_hole_size = Screw_size * 1.125;
// According to
// https://www.engineersedge.com/hardware/standard_metric_hex_nuts_13728.htm, at
// least for M3 and M4
Nut_height = 0.8 * Screw_size;

Thickness = Nut_height + Min_thickness;

module part(anchor=CENTER, spin=0, orient=TOP) {
    size = [Width, Thickness, Height];

    module _part() {
        diff("cutme") cuboid(size, rounding=Thickness/4) {
            up(Hole_z_offset) {
                position(BACK) {
                    // TODO: collision detection with the screw holes
                    hook_peg(anchor=FRONT);
                }
                // Screw holes, distributed around centre to avoid collision
                // TODO: need some way to not poke out the back, as that's where
                // the pegboard is -- unless the screw is perfectly sized
                // (m4x8mm seems to be OK for my hinge thing)
                tags("cutme") zcopies(n=2, spacing=Screw_hole_spacing) {
                    ycyl(d=Screw_hole_size, h=size.y+2*$eps);
                    position(BACK) back($eps) ycyl(d=1.154 * Nut_width+2*Slop, $fn=6, h=Nut_height+Slop, anchor=BACK);
                }
            }
        }
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

anchor = Add_base ? FRONT : CENTER;
orient = Add_base ? FRONT : TOP;

add_base(enable=Add_base)
if (Part == "All") {
    part(anchor=anchor, orient=orient);
}

$export_suffix = str(Part, "-take1");
