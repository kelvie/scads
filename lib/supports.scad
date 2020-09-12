include <BOSL2/std.scad>

Show_sample = false;

module bottom_support(size, chamfer, edges=edges("ALL"),
                      angle=45,
                      orient=TOP, spin=0, anchor=TOP) {
    sz = [size.x, size.y, size.y+chamfer];

    module _mk_support() {
        intersection() {
            cuboid(sz, chamfer=chamfer, edges=edges("ALL", except=[TOP, BOTTOM, FRONT]));
            back(chamfer)
                up(chamfer)
                xrot(angle)
                cuboid([size.x, size.y*2, size.y], chamfer=chamfer, anchor=BOTTOM);
        }
    }
    attachable(size=sz, orient=orient, spin=spin, anchor=anchor) {
        _mk_support();
        children();
    }
}


if (Show_sample)
cuboid([10, 20, 30], chamfer=2, edges=edges("ALL", except=[BOTTOM, FRONT])) {
    position(BOTTOM)
        bottom_support([10, 20], chamfer=2);
}

