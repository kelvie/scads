// Calipers holder for the skadis pegboard

// Amount of thickness to remove from the peg to make sure it fits the pegboard.
// Increase if the fit is too tight
Peg_thickness_tolerance = 0.2; // [0:0.025:0.2]

// Length of the part that sticks down behind the peg
Peg_back_length = 10; // [7:0.5:15]
Peg_angle = 67.5; // [45:7.5:90]
Plate_size = [60, 3, 40];

// Thickness of walls
Wall_thickness = 3;

// The height of the guard holding the front of the calipers
Guard_height = 5;

// Extra thickness to add to the thickness
Tolerance = 1;


/* [Calipers specs (see diagrams/calipers.svg)] */

// Max thickness of the calipers
Calipers_thickness = 10;

Left_height = 27;
Right_height = 12.5;
Mid_width = 28;
Left_side_angle = 13.134;
Left_platform_width = 10;
Right_platform_width = 10;

// Left_side_angle calculation
// point1 = [0.5, 1.2];
// point2 = [2, 0.85];
// echo("Left side angle is : ", atan2(point1.y - point2.y, point2.x - point1.x));

include <lib/BOSL2/std.scad>
use <lib/skadis.scad> // hookPeg
use <lib/text.scad> // addText

/* [Hidden] */
$fa=$preview ? 10 : 5;
$fs=0.025;


// corner rounding for pegs for some reason openscad/BOSL crashes when it's too big
pegRounding = 1.6;

// calipers need 10mm thickness in Y direction
module makeHookPeg() {
    hookPeg(
        pegTolerance=Peg_thickness_tolerance,
        pegAngle=Peg_angle,
        backLength=Peg_back_length,
        rounding=pegRounding
        );
}

module makePlatform(width, angle=0) {
    sz = [width, Calipers_thickness + Tolerance+Wall_thickness, Wall_thickness];
    chamfer = sz.z/3;
    negChamfer = 2*chamfer;

    yrot(-angle)
        union () {
        // Horizontal part
        cuboid(
            size=sz,
            anchor=BACK+LEFT+TOP,
            chamfer=chamfer,
            edges=edges("ALL", except=[BACK])
            );

        // Negative chamfer to ease stress on connection
        down(sz.z) xrot(-90) right(chamfer) cuboid(
            size=[sz.x - negChamfer, sz.z, negChamfer],
            anchor=BACK+LEFT+TOP,
            chamfer=-negChamfer,
            edges=TOP
            );

        // Front guard
        fwd(sz.y - Wall_thickness)
            up(Guard_height)
            cuboid(
                size=[sz.x, Wall_thickness, Guard_height+Wall_thickness],
                anchor=BACK+LEFT+TOP,
                chamfer=chamfer
                );
    }
}

sz = Plate_size;

difference() {
    union() {
       up(5) {
            // back plate
            cuboid(sz, anchor=BACK+TOP, chamfer=sz.y / 3);

            // Left side mounting platform
            fwd(sz.y) down(Left_height) left(Mid_width / 2)
                mirror([1, 0, 0])
                makePlatform(Left_platform_width, Left_side_angle);

            // Right side mounting platform
            fwd(sz.y) down(Right_height) right(Mid_width / 2)
                makePlatform(Right_platform_width, 0);

        }
        // Skadis Mounting pegs
        // They are 40mm apart, 30m down for a stabilization peg
        left(20) {
            makeHookPeg();
            down(30) straightPeg();
        }
        right(20) {
            makeHookPeg();
            down(30) straightPeg();

        }
    }
    down(2) fwd(sz.y) xrot(90)
        addText("Calipers", t=0.5, h=4);
}
