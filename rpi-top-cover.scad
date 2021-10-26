include <lib/BOSL2/std.scad>
include <lib/add-base.scad>

// Raspberry Pi 4b top mount, using standoffs.
// This supports mounting a 40mm noctua fan to roughly where the CPU is.
// This was meant for a two-stack of raspberry pi 4's, and the fan is meant to
// cool both at once.

Add_base = false;
Part = "All"; // [All]

X_size = 58 + 3.5 + 3.5;
Y_size = 56;
Thickness = 2;
Fan_mount_thickness = 2;

// 32mm for 40mm fan
Fan_hole_spacing = 32;

Slop = 0.15;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

// Noctua fan
Fan_hole_diameter = 4.3;

// From Pi 4 schematics
Screw_hole_Y_spacing = 49;
Screw_hole_X_spacing = 58;

// RPi4 uses 2.7 apparently, but we should be using nuts, and if this warps even
// a little, the screws get hard to insert
Screw_hole_size = 3;
Hole_to_CPU_spacing = 25.75;

module part(anchor=CENTER, spin=0, orient=TOP) {
    size = [X_size, Y_size, Thickness];

    module _screw_hole() {
        cyl(d=Screw_hole_size, h=Thickness+$eps);
    }
    module _fan_mount() {
        fan_mount_x = 10; // Fan_hole_diameter + Fan_mount_thickness*2;
        up(Thickness/2+ fan_mount_x/2)
            back(Fan_mount_thickness / 2)
            mirror_copy(RIGHT)
            left(Fan_hole_spacing / 2) {
            ycyl(d=fan_mount_x, h=Fan_mount_thickness);
            ycyl(d=Fan_hole_diameter, h=Fan_mount_thickness+Slop, $tags="neg");
            cuboid([fan_mount_x, Fan_mount_thickness, fan_mount_x/2], anchor=TOP);
        }
    }

    module _part() {
        diff("neg")
            cuboid(size, rounding=3, edges=edges("ALL", except=[TOP, BOTTOM])) {
            mirror_copy(LEFT)
                mirror_copy(BACK)
                right(Screw_hole_X_spacing / 2)
                fwd(Screw_hole_Y_spacing / 2)
                _screw_hole($tags="neg");

            mirror_copy(BACK) position(FRONT)
                left(Screw_hole_X_spacing / 2 - Hole_to_CPU_spacing) {
                _fan_mount();
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
if (Part == "All") {
    part(anchor=anchor);
}

$export_suffix = str(Part, "-take1");
