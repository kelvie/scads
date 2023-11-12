include <lib/BOSL2/std.scad>
include <lib/add-base.scad>

Add_base = true;
Part = "All"; // [All]

Slop = 0.15;

// For add_base, the minimum bottom thickness
Min_bottom_thickness = 4;

Top_diameter = 25;
Bottom_diameter = 50;


/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

Panel_edge_to_ground = 11;

// The distance to the bottom of the peg
Panel_edge_to_peg = 6.44;

Peg_diameter = 3.74;
Panel_thickness = 1.6;

// The amount the peg sticks out
Peg_height = 7.78;

module part(anchor=CENTER, spin=0, orient=TOP) {
    total_z = Panel_edge_to_ground + Panel_edge_to_peg + 2*Peg_diameter;
    size = [Bottom_diameter, Bottom_diameter, total_z];

    module _part() {
        down(total_z/2) // to make sure origin is in the middle
            zcyl(d=Bottom_diameter, h=Panel_edge_to_ground, $fn=100, anchor=BOTTOM) {
            // Add the peg holder to the top
            diff("remove")
                position(TOP) zcyl(d=Top_diameter, h=total_z - Panel_edge_to_ground,
                                   rounding1=-2.5,
                                   $fn=100,
                                   anchor=BOTTOM) {
                tag("remove") up($eps) position(TOP) {
                    // cutout for the panel
                    cuboid(size=[Bottom_diameter, Panel_thickness + 2*Slop, size.z],
                           rounding=-0.5, edges=TOP, anchor=TOP);
                    // cutout for the peg
                    cuboid(size=[Peg_diameter + 2*Slop, Peg_height + Slop, total_z - Panel_edge_to_peg - Panel_edge_to_ground], anchor=BACK+TOP,
                           rounding=-0.5, edges=TOP);
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

$export_suffix = str(Part, "-take1");
