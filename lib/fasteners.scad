include <BOSL2/std.scad>

Screw_hole_diameter = 3.2;

// Assumes a countersunk screw
Screw_head_height = 1.65;

Nut_thickness = 2.4;
Nut_width = 5.5;
Slop = 0.1;

Screw_size = 3;

Show_sample = false;
Sample_angle = 45; // [0:15:90]

/* [Hidden] */
hole_d = Screw_hole_diameter;
screw_head_h = Screw_head_height;
screw_head_w = Screw_size + 2*screw_head_h;

module m3_screw_rail(l, h, anchor=TOP, orient=TOP, spin=0) {
    size = [l + screw_head_w, screw_head_w, h];

    inner_length = l;
    module _cutout() {
        hull()
            mirror_copy(LEFT)
            left(inner_length/2)
            cyl(d=hole_d, h=h);

        hull()
            mirror_copy(LEFT)
            left(inner_length/2)
            up(h/2)
            cyl(d2=screw_head_w,
                d1=Screw_size,
                h=screw_head_h,
                anchor=TOP);
    }

    attachable(size=size, anchor=anchor, orient=orient, spin=spin) {
        _cutout();
        children();
    }
}

function m3_screw_head_width() = screw_head_w;

// TODO: add a max length of rail, and make it look nice

// Creates a screw rail grill -- that is, a grill that can be used as a
// countersunk screw rail.
// This is useful for attaching parts that might need manual adjustment
module m3_screw_rail_grill(w, l, h, anchor=TOP, spacing_mult=1.1, angle=45) {
    inner_l = l - screw_head_w;
    inner_w = w - screw_head_w;

    slope = tan(angle);
    spacing = spacing_mult * screw_head_w;
    y_spacing = spacing * sqrt(pow(slope, 2) + 1);
    x_spacing = y_spacing / slope;

    max_i = floor(max(inner_l / y_spacing, inner_w / x_spacing));

    if (angle % 180 == 0) {
        ycopies(l=inner_l, spacing=spacing)
            m3_screw_rail(l=inner_w, h=h, anchor=anchor, spin=angle);
    } else if (angle % 180 == 90) {
        xcopies(l=inner_w, spacing=spacing)
            m3_screw_rail(l=inner_l, h=h, anchor=anchor, spin=angle);
    } else {
        for (i = [-max_i:max_i]) {
            yoff = i*y_spacing;

            x1 = -inner_w/2;
            x2 = inner_w/2;
            y1 = slope * x1 + yoff;
            y2 = slope * x2 + yoff;

            y1_ = max(y1, -inner_l/2);
            x1_ = (y1_ - yoff) / slope;

            y2_ = min(y2, inner_l/2);
            x2_ = (y2_ - yoff) / slope;

            l = sqrt(pow((x1_-x2_), 2) + pow((y1_-y2_), 2));
            ydiff = y1_ - y1 + y2_ - y2;
            xdiff = x1_ - x1 + x2_ - x2;
            if (y2_ > -inner_l/2 && x2_ > -inner_w/2)
                back(yoff + ydiff/2 )
                    right(xdiff/2)
                    m3_screw_rail(l=l, h=h, anchor=anchor, spin=angle);
        }
    }
}

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

function m3_sqnut_holder_size(wall, orient=TOP, spin=0, anchor=CENTER, chamfer,
                         edges=edges("ALL"), slop=Slop) =
    [nw, nt, nw] + wall * [2,2,1] + slop*[1,1,1];

module m3_sqnut_holder(wall, orient=TOP, spin=0, anchor=CENTER, chamfer,
                       edges=edges("ALL"), slop=Slop) {
    eps = $fs/10;
    sz = m3_sqnut_holder_size(wall, orient, spin, anchor, chamfer, edges, slop);

    attachable(size=sz, orient=orient, spin=spin, anchor=anchor) {
        difference() {
            cuboid(sz,
                   chamfer=chamfer,
                   edges=edges);
            up(wall/2 + eps)
                m3_sqnut_cutout(hole_height=wall+eps,
                                chamfer=chamfer, slop=slop);
        }
        children();
    }
}

if (Show_sample) {
    $fa = $preview ? 10 : 5 ;
    $fs = 0.025;
    diff("rail")
        cuboid([85, 40, 2])
        attach(TOP, $overlap=-$fs/4)
        m3_screw_rail_grill(w=$parent_size.x-2,
                            l=$parent_size.y-2,
                            h=4,
                            $tags="rail", angle=Sample_angle);
 }
