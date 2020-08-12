include <BOSL2/std.scad>
include <BOSL2/hull.scad>
include <lib/skadis.scad>

Square_width = 20;
Square_thickness = 2;
Tolerance = 0.2;
Wall_size = 2;
Rounding = 0.4;
Text = "20mm square";

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

module addText() {
    difference() {
        children(0);
        back(0.2 - 0.001) up(0.5) fwd(Wall_size)
            xrot(90) linear_extrude(0.2)
            text(text=Text, size=1, halign="center", font="Roboto Slab");
    }
}

addText() union() {
    hookPeg();
    up(5) cuboid([10, 2, 40], anchor=BACK+TOP, rounding=Rounding);
    down(30) straightPeg();
    rect_tube(
        isize=[Square_width + Tolerance, Square_thickness + Tolerance],
        wall=Wall_size,
        h=8,
        anchor=TOP+BACK,
        rounding=Rounding,
        irounding=Rounding
        );
}
