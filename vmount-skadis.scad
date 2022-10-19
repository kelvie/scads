include <lib/BOSL2/std.scad>
include <lib/fasteners.scad>
include <lib/add-base.scad>
include <lib/text.scad>

Add_base = false;
Part = "All"; // [All]

Height = 25;
Wall_thickness = 3.5;
Slop = 0.15;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

Slot_width  = 40;
V_height = 35;
V_width_top = 32;
V_width_bottom = 14;
V_depth = 5; // probably needs some slop
V_bevel_angle = 30; // the male side seems to be 28°, so this includes tolerance?
V_angle = 15; // per side
Thickness = V_depth + Wall_thickness;

outer_sz = [40-2*Slop, Height, Thickness];
inner_sz = [40-2*Slop, Height, Thickness];

module part(anchor=CENTER, spin=0, orient=TOP) {
    size = outer_sz;

    module _part() {
        rounding=0.5;
        // #cuboid([13.8, 35, size.z]);
        diff("cutme") {
            fwd((outer_sz.y - inner_sz.y)/2) cuboid(inner_sz, rounding=rounding) {
            // should actually be 15°
            scale_factor = (V_width_top - V_width_bottom) / 2 / V_height;

            // TODO: chamfer the top and add some text at an angle
            //
            // TODO: chamfer sharp edges, maybe redraw this whole thing using
            // the angle, and some hulled spheres?
            position(TOP) tags("cutme")
                up($eps)
                fwd(V_height/2) // Anchor the front edge to center
                back(Height/2) // align front edge with overall height
                down(V_depth/2)
                xrot(90)
                up(V_height/2 + $eps)
                yrot(180)
                hull()
                mirror_copy(LEFT)
                multmatrix(m = [[1, 0, scale_factor, 0],
                                [0, 1, 0, 0],
                                [0, 0, 1, 0]])
                linear_extrude(height=V_height+2*$eps)
                trapezoid(h=V_depth,
                          w2=V_width_bottom - 2*V_depth * tan(V_bevel_angle) + 2*Slop,
                          w1=V_width_bottom + 2*Slop);
            }

            // Hard coded numbers her due to to text sizing -- maybe extend this further back?
            position(BACK+TOP) fwd(3) down(V_depth-2*$eps) tags("cutme") xrot(-45) {
                cuboid([V_width_top-6, 5, 4], anchor=BOTTOM+FRONT);
                up($eps) back(1) label("V-mount battery", font="PragmataPro", anchor=FRONT+TOP);
            }

            // Hole(s) for https://www.printables.com/model/228663-t-nuts-for-ikea-skadis-pegboards
            down(size.z / 2) cuboid([outer_sz.x, outer_sz.y, outer_sz.z], anchor=BOTTOM, rounding=rounding) {

                // 40mm spacing for skadis, uncomment if you want two
                // mirror_copy(LEFT) right(20)
                {
                    up($eps) position(TOP) tags("cutme") {
                        down($eps) cyl(d=5, h=size.z, anchor=BOTTOM);

                        m2dot5_hole(h=2*size.z, anchor=TOP, countersunk_h=1.25);

                    }
                    position(BOTTOM) {
                        zcyl(r2=3.5, r1=3.5+0.8, h=0.8+$eps, anchor=TOP, $tags="cutme");
                        hull() mirror_copy(FRONT) fwd(5) zcyl(r2=2.5+0.8, r1=2.5, h=0.8, anchor=TOP);
                    }
                }
            }

        }
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

anchor = Add_base ? FRONT : CENTER;
orient = Add_base ? FRONT : TOP;

add_base(enable=Add_base)
if (Part == "All") {
    part(anchor=anchor, orient=orient);
}

$export_suffix = str(Part, "-take1");
