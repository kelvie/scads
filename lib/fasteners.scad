include <BOSL2/std.scad>

Screw_hole_diameter = 3.2;

// Assumes a countersunk screw
Screw_head_height = 1.65;

Nut_thickness = 2.4;
Nut_width = 5.5;
Slop = 0.1;


/* [Hidden] */
nw = Nut_width;
nt = Nut_thickness;
module m3_sqnut_cutout(hole_height, hole_diameter=Screw_hole_diameter, slop=Slop,
                       orient=TOP, spin=0, anchor=CENTER, chamfer) {
    hh = hole_height;
    hd = hole_diameter;
    chamfer = is_def(chamfer) ? -chamfer : undef;
    cuboid([nw, nt, nw] + slop*[1,1,1], orient=orient, spin=spin,
           anchor=anchor, chamfer=chamfer, edges=TOP)
        cyl(d=hd, h=nt+slop+2*hh, orient=FRONT);
}

module m3_sqnut_holder(wall, orient=TOP, spin=0, anchor=CENTER, chamfer,
                       edges=edges("ALL"), slop=Slop) {
    eps = $fs/10;
    sz = [nw, nt, nw] + wall * [2,2,1] + slop*[1,1,1];

    attachable(size=sz, orient=orient, spin=spin, anchor=anchor) {
        difference() {
            cuboid(sz,
                   chamfer=chamfer,
                   edges=edges);
            up(wall/2 + eps)
                m3_sqnut_cutout(hole_height=wall+eps,
                                chamfer=chamfer);
        }
        children();
    }
}
