include <lib/BOSL2/std.scad>
include <lib/patterns.scad>

Fan_size = 92;
Fan_height = 14;
Fan_hole_size = 4.3;
Fan_hole_spacing = 82.5;
Fan_grill_hole_size = 10;
Wall_thickness = 3;


/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

wall = Wall_thickness;
grill_size = [Fan_size, Fan_size, wall];

module fan_grill(anchor=CENTER, spin=0, orient=TOP) {
    size=grill_size;
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        union() {
            render() border_cut(size=size, wall=wall)
                hex_grid(size=[size.x, size.y], h=size.z,
                         d=Fan_grill_hole_size);

            screw_mount_length = Fan_size - Fan_hole_spacing;
            mirror_copy(LEFT)
                mirror_copy(FRONT)
                translate(Fan_hole_spacing / 2 * [1, 1, 0]) {
                cyl(h=wall, d=screw_mount_length-$eps);
                cuboid([screw_mount_length/2, screw_mount_length, wall], anchor=LEFT);
                cuboid([screw_mount_length, screw_mount_length/2, wall], anchor=FRONT);
            }
        }
        children();
    }
}

module part(anchor=CENTER, spin=0, orient=TOP) {
    // TODO: fix
    size=grill_size;
    module _part() {
        difference() {
            fan_grill() {
                mirror_copy(BACK)
                position(FRONT+BOTTOM)
                    cuboid([$parent_size.x, wall, Fan_height+wall],
                           edges=edges("ALL", except=[BACK, BOTTOM]),
                           anchor=BACK+BOTTOM);
            }
            // Cut out screw holes
            mirror_copy(LEFT)
                mirror_copy(FRONT)
                translate(Fan_hole_spacing / 2 * [1, 1, 0])
                cyl(h=2*wall, d=Fan_hole_size);

        }

    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

part();
