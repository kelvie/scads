include <lib/BOSL2/constants.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/metric_screws.scad>
include <lib/addBase.scad>

Box_size = [30, 20, 10];
Tolerance = 0.1; // 0.1 for press fit tolerance

// The m3 nuts I have are not the standard 2.4mm thick for some reason
M3_nut_thickness = 2.6; // [2.4:0.2:2.6]

/* [hidden] */
$fa=5;
$fs=0.025;

// These cut out the nut, in the -z direction, as well as a hole "holeHeight
// above the nut, and holeSink below it"
module nutCutout(id, h, holeDiameter=0, holeHeight=0, holeSink=0) {
    module nut() {
        down(h) linear_extrude(h) hexagon(id=id, spin=90, anchor=LEFT);
    }

    union() {
        hull() {
            nut();
            fwd(id/2) nut();
        }
        totalHoleHeight = holeSink + h + holeHeight;
        $eps = totalHoleHeight / 1000;

        if (holeDiameter > 0 && holeHeight > 0)
            down(holeSink + h) back(id/2) cyl(d=holeDiameter, h=totalHoleHeight+$eps, anchor=BOTTOM);
    }
}

bs = Box_size;
hh = 2;

module nut(size=3, h, tolerance=Tolerance) {
    id_ = get_metric_nut_size(size) + tolerance;
    h_ = (h == undef ? get_metric_nut_thickness(size) : h) + tolerance;
    hd = size*1.08;

    nutCutout(id=id_, h=h_, holeDiameter=hd, holeHeight=hh, holeSink=10);
}


module addText(text) {
    t = 0.4;
    #down(t - 0.01) linear_extrude(t) text(font="Oxygen Sans", text=text, size=2, halign="center", valign="center");
}

addBase(0.3, 1.5) up(bs.z) difference() {
    cuboid(bs, anchor=TOP, chamfer=1);

    fwd(bs.y/4)
        addText("M3");

    zrot(180) fwd(bs.y/4)
        addText("M2.5");

    down(hh) {
        fwd(bs.y/2) {
            left(5) nut(3, h=M3_nut_thickness, tolerance=0.2);
            right(5) nut(3, h=M3_nut_thickness, tolerance=0.2);
        }

        zrot(180) fwd(bs.y/2) {
            left(5) nut(2.5);
            right(5) nut(2.5);
        }
    }

}
