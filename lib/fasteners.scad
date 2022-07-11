include <BOSL2/std.scad>

Screw_hole_diameter = 3.2;

Part_to_show = "Square nut rail"; // [Rail grill, Square nut rail]
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

module m3_screw_hole(h, extra_height=0, outset=0, anchor=TOP, orient=TOP, spin=0) {
    m3_screw_rail(l=0, h, extra_height, outset, anchor, orient, spin)
        children();
}

module m3_screw_rail(l, h, extra_height=0, outset=0,
                     anchor=TOP, orient=TOP, spin=0) {
    size = [l + screw_head_w, screw_head_w, h+extra_height];

    inner_length = l;
    module _cutout() {
        if (extra_height > 0) hull()
        mirror_copy(LEFT)
            left(inner_length/2)
            up(size.z/2+$eps)
            cyl(d=screw_head_w+2*outset, h=extra_height, anchor=TOP);

        down(extra_height) {
            hull()
                mirror_copy(LEFT)
                left(inner_length/2)
                cyl(d=hole_d, h=h);

            hull()
                mirror_copy(LEFT)
                left(inner_length/2)
                    up(size.z/2+2*$eps)
                cyl(d2=screw_head_w,
                    d1=Screw_size,
                    h=screw_head_h,
                    anchor=TOP);
    }
}

    attachable(size=size, anchor=anchor, orient=orient, spin=spin) {
        _cutout();
        children();
    }
}

function m3_screw_head_width() = screw_head_w;
function m3_screw_head_height_countersunk() = screw_head_h;

// Creates a screw rail grill -- that is, a grill that can be used as a
// countersunk screw rail.
//
// This is useful for attaching parts that might need manual adjustment
//
// Parameters:
//   `w` and `l` determine the area to cover
//   `angle` is the angle of the rail
//   `maxlen` ensures that rails won't be longer than the specified length by
//       breaking them up
//   `outset` when used with `extra_height`, the extra width (in all
//       directions) to make the extra height
//   `extra_height` is the extra cut out on top of the screw head
module m3_screw_rail_grill(w, l, h, anchor=TOP, spacing_mult=1.1, angle=45,
                           maxlen=undef, outset=0, extra_height=0) {
    inner_l = l - screw_head_w;
    inner_w = w - screw_head_w;

    slope = tan(angle);
    spacing = spacing_mult * screw_head_w;
    y_spacing = spacing * sqrt(pow(slope, 2) + 1);
    x_spacing = y_spacing / slope;

    module _rail(l, anchor) {
        m3_screw_rail(l=l, anchor=anchor, h=h, spin=angle, outset=outset,
                      extra_height=extra_height);
    }
    function _rail_len(l, n) = (l - spacing * (n-1)) / n;
    function _get_n(l, maxlen, n=1) =
        (_rail_len(l, n) < maxlen) ? n : _get_n(l, maxlen, n+1);

    assert(is_undef(maxlen) || maxlen > 2*spacing);

    module _split_rail(l, offset=false) {
        if (is_def(maxlen)) {
            n = _get_n(l, maxlen);
            needs_offset = offset && n > 1;
            longlen = _rail_len(l, n);
            shortlen = (l - n*spacing - longlen*(n-1))/2;
            assert(shortlen > 0, "maxlen is too short");
            translate(zrot(angle, p=(l/2 + screw_head_w/2) * LEFT))
                for (i = [0:n-1 + (needs_offset ? 1 : 0)]) {
                    raillen = needs_offset && (i == 0 || i == n) ? shortlen : longlen;
                    y_adjust = (needs_offset && i > 0 ? -shortlen -spacing: 0);
                    translate(zrot(angle, p=(i*(longlen+spacing) + y_adjust) * RIGHT))
                        _rail(l=raillen, anchor=TOP+LEFT);
                }
        } else {
            _rail(l=l, anchor=anchor);
        }
    }

    max_i = floor(max(inner_l / y_spacing, inner_w / x_spacing));

    if (slope == 0) {
        ycopies(l=inner_l, spacing=spacing)
            _split_rail(l=inner_w, offset=$idx % 2 != 0);
    } else if (!is_finite(slope)) {
        xcopies(l=inner_w, spacing=spacing)
            _split_rail(l=inner_l, offset=$idx % 2 != 0);
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
                    _split_rail(l=l, offset=i%2 != 0);
        }
    }
}

/* [Hidden] */
nw = Nut_width;
nt = Nut_thickness;
module m3_sqnut_cutout(hole_height, hole_diameter=Screw_hole_diameter, slop=Slop,
                       orient=TOP, spin=0, anchor=CENTER, chamfer, length, rounding,
                       notch=false) {
    hh = hole_height;
    hd = hole_diameter;
    // Can't have notch and chamfer at the same time
    chamfer = is_def(chamfer) && !notch ? -chamfer : undef;
    sz=[nw, nt, nw] + slop*[1,1,1]
        + (is_def(length) ? [length,0,0] : [0,0,0])
        + (notch ? slop*UP : [0,0,0]);

    attachable(size=sz, orient=orient, spin=spin, anchor=anchor) {
        if (is_undef(length)) {
            difference() {
                cuboid(sz, chamfer=chamfer, edges=TOP);
                if (notch)
                    mirror_copy(BACK)
                        fwd(sz.y/2)
                        up(sz.z/2 - slop)
                        cyl(h=sz.x, r=slop, orient=RIGHT);
            }
            cyl(d=hd, h=nt+slop+2*hh, orient=FRONT);
        } else {
            difference() {
                hull()
                    xcopies(n=2, l=length)
                    cuboid([nw+slop, sz.y, sz.z], edges=TOP);
                if (notch)
                    mirror_copy(BACK)
                        fwd(sz.y/2)
                        up(sz.z/2 - slop)
                        cyl(h=sz.x, r=slop, orient=RIGHT);

            }
            hull()
                xcopies(n=2, l=length)
                    cyl(d=hd, h=nt+slop+2*hh, orient=FRONT);
        }
        children();
    }
}

function m3_sqnut_holder_size(wall, orient=TOP, spin=0, anchor=CENTER, chamfer,
                         edges=edges("ALL"), slop=Slop) =
    [nw, nt, nw] + wall * [2,2,1] + slop*[1,1,1];

module m3_sqnut_holder(wall, orient=TOP, spin=0, anchor=CENTER, chamfer,
                       edges=edges("ALL"), slop=Slop, rounding, notch=true) {
    eps = $fs/10;
    sz = m3_sqnut_holder_size(wall, orient, spin, anchor, chamfer, edges, slop);

    attachable(size=sz, orient=orient, spin=spin, anchor=anchor) {
        difference() {
            cuboid(sz,
                   chamfer=chamfer, rounding=rounding,
                   edges=edges);
            up(wall/2 + eps)
                m3_sqnut_cutout(hole_height=wall+eps,
                                chamfer=chamfer, slop=slop, notch=notch);
        }
        children();
    }
}

module m3_sqnut_rail(l, wall=2, anchor=CENTER, spin=0, orient=TOP, backwall=true, chamfer,
                     rounding, extra_h=0, bottom_l=undef, edges=EDGES_ALL, notch=true) {
    $eps = $fs / 10;

    bottom_l = is_def(bottom_l) ? bottom_l : l;
    size = [max(bottom_l, l), nt, nw] + wall*[0, backwall ? 2 : 1, 1] + extra_h * UP;
    inner_l = l - nw - 2*wall;

    pos = TOP + (backwall ? [0,0,0] :  FRONT);

    // TODO: make this out of rounded cuboid walls instead
    // TODO: use a prismoid and handle bottom_l
    module _part() {
        diff("cutme")
            cuboid(size, rounding=rounding, chamfer=chamfer, edges=edges) {
            position(pos)
                up($eps)
                m3_sqnut_cutout(hole_height=$parent_size.y + 0.1, anchor=pos,
                                length=inner_l,
                                chamfer=chamfer,
                                notch=notch,
                                $tags="cutme");
        }
    }
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

module m2_nut(h, anchor=CENTER, spin=0, orient=TOP, taper=0.4, slop=0.1) {
    // 4mm (max) width to width, converted to a cylinder radius
    d = 4 * 1.1547 + slop;

    // This adds a little dome on bottom to make it easier to fit
    cyl(d1=d, d2=d+taper, h=h, anchor=anchor, spin=spin, orient=orient, $fn=6) {
        attach(BOTTOM)
            cyl(d1=d, d2=0, h=slop, $fn=6, anchor=BOTTOM);
        children();
    }
}

module m2dot5_nut(h, anchor=CENTER, spin=0, orient=TOP, taper=0.4, slop=0.1) {
    // 5mm (max) width to width, converted to a cylinder radius
    d = 5 * 1.1547 + slop;
    eps = $fs/12;

    // This adds a little dome on bottom to make it easier to fit
    cyl(d1=d, d2=d+taper, h=h, anchor=anchor, spin=spin, orient=orient, $fn=6) {
        attach(BOTTOM)
            down(eps) cyl(d1=d, d2=0, h=slop, $fn=6, anchor=BOTTOM);
        children();
    }
}

module m2_hole(h, anchor=CENTER, spin=0, orient=TOP, taper=0, countersunk_h=0) {
    d = 2.4;
    cyl(d=d, h=h, anchor=anchor, spin=spin, orient=orient) {
        if (taper > 0)
            mirror_copy(TOP)
            attach(BOTTOM)
                cyl(h=taper, d1=d, d2=d+taper, anchor=TOP);
        // Assumes 90 degree coutnersunk angle
        if (countersunk_h > 0) {
            position(TOP)
                cyl(h=countersunk_h, d2=d + 2* countersunk_h /* * tan(45) */, d1=d, anchor=TOP);
        }

        children();
    }
}
