Screw_Size = "M3"; // [M2.5, M3]

// distance in the middle
middleWidth = 13;

// Minimum thickness of any beam
minThickness = 1;

// Tolerance between the parts
snapTolerance = 0.1;

// Layout spacing between the top and bottom piece
spacing = 30;

// Whether or not to put a small chamfer in the back of the print
Chamfer_Back = false;

// The amount to chamfer (45 degree chamfer)
Chamfer_Height = 0.2;

font = "Ubuntu";

$fn = 100;
// Epsilon for diffing parts
$eps = 0.01;


module squareWithHole(outsideLength, holeDiameter, thickness) {
    dx = outsideLength / 2;
    difference() {
        cube([outsideLength, outsideLength, thickness]);
        translate([dx, dx, -0.05])
            cylinder(h=thickness+0.1, d=holeDiameter);
    }
}

module chamferBack(yOffset, width) {
    difference() {
        children(0);
        if (Chamfer_Back) translate([0, yOffset, 0])
            rotate([0, 90, 0])
            linear_extrude(width)
            polygon([[0, 0], [0, -Chamfer_Height], [-Chamfer_Height, 0]]);
    }
}

// Mirrors the part and does some final translations
module finishPart(v, label) {
    union() {
        chamferBack(v.y, v.x*2) translate ([v.x, 0]) union() {
            translate([-v.x, 0]) children(0);
            mirror([1, 0, 0]) translate([-v.x, 0]) children(0);
        }
        // Label
        translate([v.x, 0, 0.2]) rotate([90, 0, 0])
                      linear_extrude(height=0.1)
                      text(label, size=0.8, font=font, halign="center");



    }
}
module basePart(outerCube, nutWidth, holeDiameter, nutHeight, minThickness) {
    difference() {
        cube(outerCube);

        // screw hole
        translate([nutWidth / 2, nutWidth/2, -$eps]) cylinder(h=outerCube.z + 2*$eps, d=holeDiameter);

        // nut hole
        translate([-$eps, -$eps, minThickness]) cube([nutWidth+$eps, nutWidth+2*$eps, nutHeight+snapTolerance]);
    }

}

module bottomCutOut(outerCube, minThickness, nutWidth, nutHeight) {
    union() {
        // Remove the top part
        translate([-$eps, -$eps, nutHeight + 2*minThickness]) cube(outerCube + [2*$eps, 2*$eps, 0]);

        // Cut out the middle section
        translate([nutWidth + minThickness, -$eps, 2*minThickness]) cube(outerCube + [0, 2*$eps, 0]);
    }
}

module makePart(middleWidth=middleWidth,
                nutWidth,
                nutHeight,
                holeDiameter,
                screwLength,
                minThickness,
                screwHeadHeight,
                type,
                label,
    )
{
    // Overall dimensions of cube
    outerCube = [(nutWidth*2 + middleWidth + minThickness*2) / 2, nutWidth, screwHeadHeight + screwLength];

    if (type == "bottom")
        finishPart(outerCube, str(label, "  -  ", "BOTTOM")) difference() {
            basePart(outerCube, nutWidth, holeDiameter, nutHeight, minThickness);
            bottomCutOut(outerCube, minThickness, nutWidth, nutHeight);
        }

    if (type == "top")  {

        // 0.25mm is the amount to carve off the bottom to make space for the
        // piece of steel it's clamping (I measured it at 0.3mm, but we want it
        // to be tight)
        dz = 2*minThickness+0.25;

        finishPart(outerCube, str(label, "-", "TOP")) translate([0, 0, -dz]) difference() {

            // Start with the opposite of the bottom piece
            intersection() {
                basePart(outerCube, nutWidth, holeDiameter, nutHeight, minThickness);
                bottomCutOut(outerCube, minThickness, nutWidth, nutHeight);
            }

            // Carve out 0.2mm off the bottom to fit the stainless plate (I measured it to be 0.3mm)
            translate([-$eps, -$eps]) cube([outerCube.x + 2*$eps, outerCube.y + 2*$eps, dz]);

            // Cut out the screw head height off the side
            translate([-$eps, -$eps, screwLength]) cube([nutWidth+2*$eps, outerCube.y+2*$eps, screwHeadHeight+$eps]);

            // Carve out the snap tolerance on the side to connect to the bottom piece
            translate([0, -$eps]) cube([nutWidth+snapTolerance/2+minThickness, outerCube.y + 2*$eps, 2*minThickness + nutHeight]);
        }
    }

}

module bothParts(nutHeight, nutWidth, holeDiameter, label, screwLength, screwHeadHeight=0) {
    makePart(nutWidth=nutWidth,
             nutHeight=nutHeight,
             holeDiameter=holeDiameter,
             minThickness=minThickness,
             screwHeadHeight=screwHeadHeight,
             screwLength=screwLength,
             type="bottom", label=label);

    translate([spacing, 0])
        makePart(nutWidth=nutWidth,
                 nutHeight=nutHeight,
                 holeDiameter=holeDiameter,
                 screwHeadHeight=screwHeadHeight,
                 minThickness=minThickness,
                 screwLength=screwLength,
                 type="top", label=label);
}

// TODO: calculate width based on nutWitdh, and cut a smaller hole

// Need 2.9mm hole clearance for M2.5, head size is 4.5
// M2.5 nut is 2mm high (max)
if (Screw_Size == "M2.5")
    bothParts(2, 5, 2.9, "M2.5", screwHeadHeight=1.3, screwLength=6);

// M3 nut height is 2.6, but we need 6mm for threads to go through
// need 3.4mm hole clearance for M3, head size is 5.5
if (Screw_Size == "M3")
    bothParts(2.6, 6, 3.4, "M3", screwHeadHeight=2.3, screwLength=6);
