
include <lib/BOSL2/std.scad>

include <lib/add-base.scad> // add_base

Top_diameter = 45;
Bottom_diameter = 40;
Height = 20;
Chamfer = 1;

Add_base = true;

/* [Hidden] */
$fs = 0.025;
$fa = 1;
$eps = $fs/4;

module part(anchor=CENTER, spin=0, orient=TOP) {
    size = [Top_diameter, Top_diameter, Height];

    top_height = (Top_diameter - Bottom_diameter) / 2;
    module _part() {
        intersection() {
            cyl(d=Top_diameter - Chamfer, h=Height);
            cyl(d=Bottom_diameter, h=Height)
                attach(TOP)
                cyl(d2=Top_diameter, d1=Bottom_diameter, h=top_height, anchor=TOP);
        }
    }
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}


add_base(enable=Add_base)
part(anchor=BOTTOM);
