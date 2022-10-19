include <lib/BOSL2/std.scad>
include <lib/fasteners.scad>
include <lib/add-base.scad>
include <lib/text.scad>

Add_base = false;
Part = "All"; // [All]

Height = 25;
Wall_thickness = 2.0;
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
rounding=0.5;

module part(anchor=CENTER, spin=0, orient=TOP) {
    size = outer_sz;

    module _part() {
        // #cuboid([13.8, 35, size.z]);
        diff("cutme") {
            fwd((outer_sz.y - inner_sz.y)/2) cuboid(inner_sz, rounding=rounding) {
            // should actually be 15°
            scale_factor = (V_width_top - V_width_bottom) / 2 / V_height;

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

            // Add an extension at the top with some text
            text_height = Wall_thickness / 2 * sqrt(2);
            position(BACK+BOTTOM) fwd(2*rounding) cuboid([size.x, Wall_thickness+2*rounding, Wall_thickness], anchor=BOTTOM+FRONT,
                                                         rounding=rounding, edges=edges("ALL", except=TOP));
            position(BACK+TOP) down(V_depth-2*$eps) xrot(-45) {
                tags("cutme") {
                    cuboid([size.x+2*$eps, Wall_thickness*sqrt(2), Wall_thickness+2*rounding], anchor=BOTTOM+FRONT);
                    up($eps) back(text_height/2) label("V-mount battery", font="PragmataPro", anchor=FRONT, h=text_height, valign="center");
                }
        }

            // Hole(s) for https://www.printables.com/model/228663-t-nuts-for-ikea-skadis-pegboards
            down(size.z / 2) cuboid([outer_sz.x, outer_sz.y, outer_sz.z], anchor=BOTTOM, rounding=rounding) {
                // 40mm spacing for skadis, uncomment if you want two
                // mirror_copy(LEFT) right(20)
                {
                    up(2*$eps) down(V_depth) position(TOP) tags("cutme") {
                        down($eps) cyl(d=5, h=size.z, anchor=BOTTOM);

                        m2dot5_hole(h=2*Wall_thickness, anchor=TOP, countersunk_h=1.25);

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

// Inset needs to be at least 0.2
inset = min((Wall_thickness - rounding) / 2 - 0.2, 1.5);
echo("Inset is ", inset);
add_base(enable=Add_base, inset=inset)
if (Part == "All") {
    part(anchor=anchor, orient=orient);
}

$export_suffix = str(Part, "-take1");
