include <lib/BOSL2/std.scad>
include <lib/anderson-connectors.scad>
include <lib/add-base.scad>

Wire_width = 5.1; // [2.0: "18AWG (red/black)", 2.2: "18AWG (2xblack)", 4.6: 20AWG - 2 conductors, 5.1: 18AWG - 2 conductors]
Number_of_wires = 1;

// Won't show up on preview
Add_base = false;
Preview_wire = true;
Orientation = "Side-by-side"; // ["Side-by-side", "Together"]

/* [Hidden] */
$fs = 0.025;
$fa = 10;
$eps = $fs/4;

module make_connector(anchor, snaps) {
    add_base(enable=!$preview && Add_base)
        pp15_cable_connector(wire_width=Wire_width, wires=Number_of_wires,
                             anchor=anchor, snaps=snaps, h=10) {

        if (Preview_wire)
            % position(TOP)
                  cuboid([Wire_width, 50, Number_of_wires*Wire_width],
                         rounding=Wire_width/2);
    }
}

if (Orientation == "Side-by-side") {
    right(10)
        make_connector(anchor=BOTTOM+LEFT, snaps="male");
    mirror(LEFT) right(10)
        make_connector(anchor=BOTTOM+LEFT, snaps="female");
 } else if (Orientation == "Together") {
    mirror_copy(TOP)
        make_connector(anchor=TOP);
 }


$export_suffix = str(Number_of_wires, "x", Wire_width, "mm-wire");
