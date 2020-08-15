include <lib/BOSL2/constants.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/metric_screws.scad>
include <lib/addBase.scad>

Box_size = [30, 20, 10];
Tolerance = 0.1; // 0.1 for press fit tolerance

/* [hidden] */
$fa=5;
$fs=0.025;

// Anchored to the bottom
module nutCutout(id, h, holeDiameter=0, holeHeight=0) {
    // Epsilon
    $eps = h / 100;

    module nut() {
        down(h) linear_extrude(h) hexagon(id=id, spin=90, anchor=LEFT);
    }

    union() {
        hull() {
            nut();
            fwd(id/2) nut();
        }
        if (holeDiameter > 0 && holeHeight > 0)
            down($eps) back(id/2) cyl(d=holeDiameter, h=holeHeight + 2*$eps, anchor=BOTTOM);
    }
}

bs = Box_size;
hh = 2;

module nut(size=3) {
    id_ = get_metric_nut_size(size) + Tolerance;
    h_ = get_metric_nut_thickness(size) + Tolerance;
    hd = size*1.08;

    nutCutout(id=id_, h=h_, holeDiameter=hd, holeHeight=hh);
}


module addText(text) {
    down(0.3 - 0.01) linear_extrude(0.3) text(font="Oxygen Sans", text=text, size=2, halign="center", valign="center");
}

addBase(0.25, 1.5) up(bs.z) difference() {
    cuboid(bs, anchor=TOP, chamfer=1);

    fwd(bs.y/4)
        addText("M3");

    zrot(180) fwd(bs.y/4)
        addText("M2.5");
    down(hh) {

        fwd(bs.y/2) {
            left(5) nut(3);
            right(5) nut(3);
        }

        zrot(180) fwd(bs.y/2) {
            left(5) nut(2.5);
            right(5) nut(2.5);
        }
    }

}
