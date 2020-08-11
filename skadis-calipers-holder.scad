// Calipers holder for the skadis pegboard

// Amount of thickness to remove from the peg to make sure it fits the pegboard.
// Increase if the fit is too tight
Peg_thickness_tolerance = 0.1; // [0:0.025:0.2]

// Length of the part that sticks down behind the peg
Peg_back_length = 10; // [7:0.5:15]
Peg_angle = 80; // [0:1:90]


// uses commit 63164b35ad7f8b1b79efffca33a2e0e1c77fd45d
include <BOSL2/std.scad>

use <lib/skadis.scad>

/* [Hidden] */
$fa=$preview ? 10 : 5;
$fs=0.025;


// corner rounding for pegs for some reason openscad/BOSL crashes when it's too big
pegRounding = 1.6;

// pegs are 40mm apart
// calipers need 10mm thickness in Y direction
module makeHookPeg() {
    hookPeg(pegTolerance=Peg_thickness_tolerance, pegAngle=Peg_angle, backLength=Peg_back_length, rounding=pegRounding);
}

union() {
    // back plate
    up(10) cuboid([60, 3, 30], anchor=BACK+TOP, chamfer=0.5);

    left(20) makeHookPeg();

    down(10) straightPeg();

    right(20) makeHookPeg();
}
