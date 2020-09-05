include <BOSL2/std.scad>

Show_sample = false;
Preview_wires = false;

$fs = 0.025;
$fa = $preview ? 10 : 5;


// Ideas:
// - A piece that snaps onto the top to keep the wires in

// Create a wire hook for attach()ing.
// `wire_diameter` includes the insulation of course
module wire_hook(wire_diameter, width, num_wires, thickness,
                 orient=TOP, spin=0, anchor=BOTTOM, slop=0.1) {
    eps = $fs/10;
    size = [width,
            (num_wires)*wire_diameter + thickness,
            thickness + wire_diameter + slop
        ];

    chamfer = thickness/8;
    module part() {
        up(size.z/2)
            cuboid([width, size.y, thickness], anchor=TOP,
                   chamfer=chamfer) {

            // A small indent to hold wires in from the top
            fwd(wire_diameter/2)
                down(2*slop)
                position(BOTTOM+BACK)
                intersect("mask")
                cyl(h=width, d=wire_diameter, orient=RIGHT,
                    anchor=RIGHT, chamfer=chamfer)
                position(RIGHT)
                cuboid([2*slop + chamfer, wire_diameter, width],
                       anchor=RIGHT,
                       $tags="mask");

            // Botttom part -- 45 degree angle for printability, as well as a
            // cutout for a wire on the bottom
            position(FRONT+TOP) intersection() {
                back(thickness)
                    diff("mask")
                    cuboid([size.x, size.x, size.z],
                           anchor=BACK+TOP, chamfer=chamfer,
                           edges=edges("ALL", except=BOTTOM)) {
                    position(BACK)
                        down((thickness)/2)
                        cyl(d=wire_diameter+slop,
                            h=width+eps,
                            chamfer=-chamfer-0.02,
                            orient=RIGHT, $tags="mask");
                }

                back(chamfer)
                    up(chamfer)
                    xrot(45)
                    cuboid([size.x, 2*size.y, size.z],
                           chamfer=chamfer,
                           anchor=TOP);
            }
        }

        // Show wires during preiew
        if ($preview && Preview_wires)
            color("red", alpha=0.2)
                down(thickness/2)
                fwd(wire_diameter/4)
                ycopies(spacing=wire_diameter, n=num_wires)
                cyl(d=wire_diameter, h=2*width, orient=RIGHT);
    }

    attachable(size=size, orient=orient, spin=spin, anchor=anchor) {
        part();
        children();
    }
}

if (Show_sample)
    cuboid([20, 1, 40])
        attach(FRONT)
        wire_hook(
            wire_diameter=2.3,
            width=10,
            num_wires=4,
            thickness=1.5,
            anchor=BOTTOM
            );
