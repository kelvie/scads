include <BOSL2/std.scad>

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

module hex_grid(size, d=10, t=3, h=3, base_height=0.3, base_inset=1,
                anchor=CENTER, spin=0, orient=TOP) {
    module _hex_grid(h, id) {
        grid2d(size=size, spacing=d, stagger=true) {
            zrot(30)
                linear_extrude(h)
                hexagon(id=id);
        }
    }

    attachable(size=[size.x, size.y, h], anchor=anchor, spin=spin,
               orient=orient) {
        down(h/2)
        difference() {
            _hex_grid(h, d+t/2);
            _hex_grid(h+$eps, d-t/2);
            // This'll get flattened on the build platform
            down($eps) _hex_grid(base_height, d - base_inset/2);
        }
        children();
    }

}

module border_cut(size, wall) {
    size_2d = [size.x, size.y];
    intersection() {
        children(0);
        cuboid(size);
    }
    difference() {
        cuboid(size);
        cuboid(size - wall * [1, 1, -1]);
    }
}
