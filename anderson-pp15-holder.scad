include <lib/BOSL2/std.scad>

include <lib/addBase.scad> // addBase
use <lib/text.scad>

Wall_thickness = 2;

// 0.2 seems to be a good balance between removability and stability
Tolerance = 0.2; // [0.1:0.05:0.31]
// Include a pin in the middle for attaching the connectors (WARNING: this makes it difficult to take out unless you increase the tolerance)
Include_roll_pin = false;
// Add a base in the bottom to account for compression in the first layers
Add_bottom_base = true;

// Whether or not to engrave the tolerance on the part
Print_tolerance = true;

// Housing type -- plugs don't cover the areas that mate
Housing_type = 0; // [0: Jack, 1: Plug]

// Which way the dovetail should point -- use "Either" if you want to fit either, but the fit will be looser
Dovetail_direction = 0; // [0: Either, 1: Left, 2: Right]

/* [ hidden ] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

// These are from the official drawings for the 1237 series
width = 7.9; // x and y
widthWithDovetail = 8.4; // x
rollPinRadius = 1.3;
tipToRollPinCentre = 9.9; // y
fullLength = 24.6; // y
wireHoleWidth = 5; // x
dovetailHeight = 12.3; // y
matedFullLength = 41.2; // y


// This version of BOSL2 has a bug with chamfering
boslFudgeFactor = 0.1;

module mirrorCopy(n) {
    children(0);
    mirror(n) children(0);
}

module mirrorDovetail(direction=Dovetail_direction) {
    if (direction == 0)
        mirrorCopy(LEFT) children(0);
    else if(direction == 1)
        mirror(LEFT) children(0);
    else if (direction == 2)
        children(0);
    else
        assert(false, str("Unknown direction value: ", direction));
}


// Creates a holder for a pair of PP15 connectors
module pp15_casing(middlePin=true, tolerance=Tolerance, dovetailDirection=Dovetail_direction, jack=Housing_type == 0) {
    housingLength = jack ? fullLength : matedFullLength - fullLength;

    outsideSz = [2*widthWithDovetail + 2*Wall_thickness, housingLength+Wall_thickness, widthWithDovetail + Wall_thickness];
    insideSz = [2*width, housingLength+Wall_thickness, widthWithDovetail] + tolerance * [1, 1, 1];
    chamfer = Wall_thickness / 3;

    echo("o: ", outsideSz, "i: ", insideSz, "chamfer:", chamfer);

    $eps = Wall_thickness / 100;

    pinR = rollPinRadius - tolerance/2;
    rollPinYOffset = tipToRollPinCentre - fullLength + housingLength;
    difference() {
        cuboid(size=outsideSz, anchor=BACK+BOTTOM, chamfer=chamfer);

        difference() {
            // Connectors' bounding box
            up(outsideSz.z)
                union () {
                // Possible BOSL bug? If I comment out this line it leaves thin faces on render
                up(0.1) back(0.1) cuboid(size=insideSz + 0.1*[0, 1, 1], anchor=BACK+TOP);

                cuboid(size=insideSz, anchor=BACK+TOP) {
                    edge_mask(edges=TOP, except=[FRONT, BACK])
                        chamfer_mask(insideSz.y, chamfer);

                    edge_mask(edges=[BACK], except=[TOP, BOTTOM])
                        chamfer_mask(insideSz.z -0.1, chamfer);

                    // Don't want the front chamfer for type == plug as it'll chamfer into the hole
                    if (jack) {
                        edge_mask(edges=[BACK], except=[LEFT, RIGHT])
                            chamfer_mask(insideSz.x - 0.1, chamfer);

                        // Corners are the intersections of both of these chamfers
                        intersection() {
                            edge_mask(edges=[BACK], except=[TOP, BOTTOM])
                                chamfer_mask(insideSz.z -0.1+2*chamfer, chamfer);
                            edge_mask(edges=[BACK], except=[LEFT, RIGHT])
                                chamfer_mask(insideSz.x - 0.1+2*chamfer, chamfer);
                        }
                    }
                }
            }



            // Side roll pins
            fwd(rollPinYOffset) {
                mirrorCopy(LEFT) left(width)
                    cyl(r=pinR, h=outsideSz.z, chamfer=chamfer, anchor=BOTTOM);

                // Optional middle roll pin
                if (middlePin)
                    cyl(r=pinR, h=outsideSz.z, chamfer=chamfer, anchor=BOTTOM);

            }

            wireHoleWallWidth = (width - wireHoleWidth) / 2;
            // Add a back wall for the wire holes
            fwd(outsideSz.y) mirrorCopy(LEFT) left(outsideSz.x/2)
                cuboid(size=[wireHoleWallWidth+Wall_thickness, Wall_thickness, outsideSz.z],
                       anchor=FRONT+BOTTOM+LEFT,
                       chamfer = chamfer
                    );
        }

        // Cut out an extra width for the dovetails near the front
        fwd(outsideSz.y-Wall_thickness)
        up(outsideSz.z)
            mirrorDovetail(dovetailDirection)
            cuboid(size=[widthWithDovetail, dovetailHeight + tolerance + chamfer, insideSz.z],
                   anchor=FRONT+TOP+LEFT,
                   chamfer=chamfer,
                   edges=BACK);

        // Draw an icon indicating which side to put in the connectors
        if (dovetailDirection != 0)
            up(Wall_thickness - 0.4) fwd(outsideSz.y-dovetailHeight / 2)
                mirrorDovetail(dovetailDirection)
                mirror(LEFT) // clearly should have drawn the icon pointing to the right
                linear_extrude(0.4) import("icons/pp15-dovetail-left.svg", center=true);


        // If there's no built-in middle roll pin, we cut out a hole instead
        if (!middlePin)
            fwd(rollPinYOffset)
                down($eps)
                cyl(r=rollPinRadius + tolerance / 2, h=outsideSz.z+2*$eps, anchor=BOTTOM);
    }
}

addBase(0.3, 1.5, enable=Add_bottom_base)
difference() {
    housingLength = Housing_type == 0 ? fullLength : matedFullLength - fullLength;
    pp15_casing(middlePin=Include_roll_pin);
    if (Print_tolerance)
        fwd(housingLength - dovetailHeight*3/4 - 1)
            up(Wall_thickness)
            addText(text=str("t: ", Tolerance), h=3);
}


