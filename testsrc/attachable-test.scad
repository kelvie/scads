include <../lib/BOSL2/std.scad>




module testpart() {
    out_sz = [10, 10, 10];
    in_sz = [8, 8, 8];
    up(2) difference() {
        cuboid(out_sz);
        up(2) cuboid(in_sz);
    }
}

module a_testpart(anchor=CENTER) {
    attachable(anchor, size=[10, 10, 10]) {
        testpart();
        children();
    }
}

a_testpart()
 position(BOTTOM) a_testpart(anchor=TOP);
