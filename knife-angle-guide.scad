include <lib/BOSL2/std.scad>
include <lib/add-base.scad>
include <lib/text.scad>

Add_base = true;
Part = "All"; // [All]

Slop = 0.15;
Knife_angle = 15;
Width = 40;
Length = 50;
Chamfer = 2;
Notch_depth = 3;
Notch_size = 5;

// For add_base, the minimum bottom thickness
Min_bottom_thickness = 4;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

module part(anchor=CENTER, spin=0, orient=TOP) {
    height = Length * tan(Knife_angle);
    size_after_chamfer = [Width, Length, height];
    size = size_after_chamfer + Chamfer * [1, 0, 1];

    module _part() {
        diff("remove") cuboid(size, rounding=size.z / 8) tag("remove") {

            // Cut off the correct angle from the top
            up(height/2)
                yrot(Knife_angle)
                cuboid(size + [Width, 2*$eps, 0]) {
                    // Additionally, in the center, cut out a notch for a rubber band
                    position(BOTTOM)
                        up($eps) cuboid([Notch_size, 2*size.y,
                                         Notch_depth+$eps], anchor=TOP,
                                         rounding=Notch_depth/4, edges=BOTTOM);
                                         };

            attach(LEFT)
                up($eps) label(str(Knife_angle, "°",), h=size_after_chamfer.z/2, font="PragamataPro", anchor=TOP);

            position(BOTTOM)
                up(height-Chamfer)
                cuboid(size + 2*$eps*[1, 1, 0], anchor=BOTTOM);

            position(RIGHT)
                left(Chamfer)
                cuboid(size, anchor=LEFT);
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
