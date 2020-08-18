include <lib/BOSL2/std.scad>

use <lib/anderson-connectors.scad> // pp15_casing
include <lib/addBase.scad> // addBase
use <lib/text.scad>

Wall_thickness = 2;

// 0.2 seems to be a good balance between removability and stability
Tolerance = 0.2; // [0.1:0.05:0.31]

// Include a pin in the middle for attaching the connectors (WARNING: this makes it more difficult to take out for the same tolerance)
Include_roll_pin = true;

// Add a base in the bottom to account for compression in the first layers
Add_bottom_base = true;

// Whether or not to engrave the tolerance on the part (mainly used for testing)
Print_tolerance = false;

// Housing type -- plugs don't cover the areas that mate
Housing_type = 0; // [0: Jack, 1: Plug]

// Which way the dovetail should point -- use "Either" if you want to fit either, but the fit will be looser
Dovetail_direction = 1; // [0: Either, 1: Left, 2: Right]

/* [ hidden ] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

module changeDirection(direction=Dovetail_direction) {
    if (direction == 2)
        mirror(LEFT) children(0);
    else
        children(0);
}

addBase(0.3, 1.5, enable=Add_bottom_base)
difference() {
    changeDirection() pp15_casing(
        middlePin=Include_roll_pin,
        jack=Housing_type == 0,
        tolerance=Tolerance,
        wall=Wall_thickness,
        dovetailLeft=Dovetail_direction != 0
        );

    // Print the tolerance for test fits
    housingLength = Housing_type == 0 ? 24.6 : 16.6;
    if (Print_tolerance)
        fwd(housingLength - 12.3 *3/4 - 1)
            up(Wall_thickness)
            addText(text=str("t: ", Tolerance), h=3);
}
