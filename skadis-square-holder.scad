include <BOSL2/std.scad>
include <BOSL2/hull.scad>

use <lib/skadis.scad>


Full_width = true;
Back_plate_width = 20;
Square_width = 20;
Square_thickness = 2;
Tolerance = 0.2;
Wall_size = 2;
Holder_height = 8;
Rounding = 0.4;
Peg_angle = 67.5; // [0:7.5:90]
Text = "20mm square";

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

// TODO: ease-in square, it's hard to insert (how do knife sheaths do it?)
module addText(vec=[0,0,0]) {
    difference() {
        children(0);
        translate(vec) back(0.2 - 0.001) up(0.5) fwd(Wall_size)
            xrot(90) linear_extrude(0.5)
            text(text=Text, size=2, halign="center", valign="center", font="Roboto Slab");
    }
}

width = Full_width ? Square_width + Tolerance + 2*Wall_size : Back_plate_width;
echo("Back plate width is ", width);

union() {
    h = Holder_height;
    hookPeg(pegAngle=Peg_angle);

    up(5) cuboid([width, Wall_size, 40], anchor=BACK+TOP, rounding=Rounding);
    down(30) straightPeg();
    addText([0, -(Square_thickness+Tolerance + Wall_size), -h/2])
        rect_tube(isize=[Square_width + Tolerance, Square_thickness + Tolerance],
                  wall=Wall_size,
                  h=h,
                  anchor=TOP+BACK,
                  rounding=Rounding,
                  irounding=Rounding
            );
}
