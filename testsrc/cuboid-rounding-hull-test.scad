include <../lib/BOSL2/std.scad>

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

rounding = 2;
module part(anchor=CENTER, spin=0, orient=TOP) {
    size = 10*[1, 1, 1];

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        cuboid(size, rounding=rounding);
        children();
    }
}

part() {
    hull() {
        move_copies([[0,0,0], 10*FRONT]) mirror_copy(LEFT) position(FRONT+LEFT+TOP)
            right(rounding)
            down(rounding)
            back(rounding)
            spheroid(r=rounding, anchor=CENTER, style="octa");
    }
}
