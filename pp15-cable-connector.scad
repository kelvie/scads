include <lib/BOSL2/std.scad>
include <lib/anderson-connectors.scad>
include <lib/add-base.scad>

Wire_width = 5.1; // [2.0: "18AWG (red/black)", 2.2: "18AWG (2xblack)", 4.4: 22AWG - 2 conductors, 4.6: 20AWG - 2 conductors, 5.1: 18AWG - 2 conductors]
Wires_per_column = 1; // [1:2]
Wires_per_row = 1; // [1:3]
Length = 10; // [5:20]
Slop = 0.15;

// Won't show up on preview
Add_base = true;
Preview_wire = true;
Orientation = "Side-by-side"; // ["Side-by-side", "Together"]

/* [Hidden] */
$fs = 0.025;
$fa = 10;
$eps = $fs/4;

module make_connector(anchor, snaps) {
    add_base(enable=!$preview && Add_base)
        pp15_cable_connector(wire_width=Wire_width, wire_cols=Wires_per_row,
                             wire_rows=Wires_per_column,
                             anchor=anchor, snaps=snaps, h=Length, tolerance=Slop) {

        // TODO: show individual wires as cylinders
        if (Preview_wire && $preview)
            color("gray", 0.5) position(TOP)
                  cuboid([Wires_per_row*Wire_width, 50, Wires_per_column*Wire_width],
                         rounding=Wire_width/2);
    }
}

if (Orientation == "Side-by-side") {
    right(5)
        make_connector(anchor=BOTTOM+LEFT, snaps="male");
    mirror(LEFT) right(5)
        make_connector(anchor=BOTTOM+LEFT, snaps="female");
 } else if (Orientation == "Together") {
    mirror_copy(TOP)
        make_connector(anchor=TOP);
 }

$export_suffix = str(Wires_per_row*Wires_per_column, "x", Wire_width, "mm-wire", "-take2");
