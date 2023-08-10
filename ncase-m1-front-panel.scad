include <lib/BOSL2/std.scad>
include <lib/add-base.scad>
include <lib/fasteners.scad>

// Front panel for ncase M1 (v5 if that matters)

Add_base = true;
Part = "All"; // [All]

Slop = 0.15;

// For add_base, the minimum bottom thickness
Min_bottom_thickness = 4;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

Total_length = 112;
Switch_hole_y_offset = 13.5;
Switch_hole_diameter = 12;

// M3
Screw_hole_size = 3.2;
// across flats
Nut_width = 5.5;
Nut_height = 2.4;

// Space between mounting holes
Mounting_hole_width = 100;

// only y, z is used
Mounting_hole_position = [0, 22, 15.5];

// Front and top in its mounted position
Front_plate_size = [112, 24, 2.2];
Top_plate_depth = 7.2;
Thickness = Front_plate_size.z;
Rounding=Thickness/4;
Min_thickness = 1.5;
Mounting_plate_depth = Mounting_hole_position.z + Screw_hole_size/2 + Min_thickness;

module part(anchor=CENTER, spin=0, orient=TOP) {
    size = Front_plate_size;

    module _part() {
        diff("remove") {
            cuboid(size, rounding=Rounding) {

                // Switch holes
                tag("remove") {
                    position(BACK) fwd(Switch_hole_y_offset)
                        zcyl(h=2*size.z, d = Switch_hole_diameter, $fn=100);
                }
                mirror_copy(LEFT) {
                    position(LEFT+BOTTOM+BACK) {
                        // Support
                        up(Rounding)
                        prismoid(h=Mounting_plate_depth - 2*Rounding,
                                 size1=[Thickness,
                                        Mounting_hole_position.y],
                                 size2=[Thickness, Thickness],
                                 shift=[0, -(Mounting_hole_position.y - Thickness)/2],
                                 rounding=Rounding,
                                 anchor=LEFT+BOTTOM+BACK);

                        // Flap for the screw below
                        fwd(Mounting_hole_position.y)
                        cuboid([2*Thickness + (size.x - Mounting_hole_width)/2,
                                Thickness,
                                Mounting_plate_depth],
                               rounding=Rounding,
                               anchor=LEFT+BOTTOM+FRONT);
                        }

                    position(BOTTOM) left(Mounting_hole_width/2)
                        up(Mounting_hole_position.z) {

                        // Nut pocket holder
                        position(BACK) fwd(Mounting_hole_position.y)
                        cuboid([Nut_width + 2*Min_thickness,
                                Nut_height + 2*Min_thickness,
                                (Nut_width + 2*Min_thickness)/2],
                               rounding=Rounding,
                               anchor=FRONT+TOP);
                        // TODO: cut out nut pocket
                        // TODO: Taper the back upward with a prismoid

                        // Mounting holes
                        tag("remove")
                            ycyl(h=2*size.y, d = Screw_hole_size, $fn=100);
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

add_base = !$preview && Add_base;
anchor = add_base ? BOTTOM : CENTER;

// Make sure there's a base for features that are at least Min_bottom_thickness,
// with at least a thickness of 0.2
base_inset = min((Min_bottom_thickness) / 2 - 0.2, 1.5);
echo("Inset to remove elephant's foot is ", base_inset);

add_base(enable=add_base, inset=base_inset)
if (Part == "All") {
    part(anchor=anchor);
}

$export_suffix = str(Part, "-take1.beta");
