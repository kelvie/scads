

// distance between holes
middleWidth = 13;
thickness = 1;
$fn = 100;
font = "Ubuntu";
Screw_Size = "M3"; // [M2.5, M3]

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
        # translate([0, yOffset, 0])
        rotate([0, 90, 0])
            linear_extrude(width)
            polygon([[0, 0], [0, -0.2], [-0.2, 0]]);
    }

}

module commonPart(nutHeight,
                  nutWidth,
                  holeDiameter,
                  label,
                  middleWidth=middleWidth,
                  extraWidth=0,
                  sliceBottom=0,
                  verticalSlice=0,
                  screwHeadHeight=0,
                  bottomPlate=0,
                  screwLength=0,

    ) {

    fullWidth = nutWidth*2 + middleWidth + thickness*2 + extraWidth*2;

    textVOffset = 0.2;

    overhangZ = screwLength == 0 ? nutHeight : screwLength - sliceBottom;

    // Label
    translate([fullWidth/2, 0, textVOffset]) rotate([90, 0, 0])
        linear_extrude(height=0.1)
        text(label, size=thickness-0.2, font=font, halign="center");

    chamferBack(nutWidth, fullWidth) union() {
        // Bottom plate, if necessary
        if (bottomPlate != 0) cube([fullWidth, nutWidth, bottomPlate]);

        translate([0, 0, bottomPlate]) union() {
            translate([0, 0, overhangZ]) {
                squareWithHole(nutWidth, holeDiameter, thickness);
            }

            translate([nutWidth, 0, overhangZ]) {
                cube([extraWidth+thickness, nutWidth, thickness]);
            }

            // Vertical part
            translate([nutWidth + extraWidth + verticalSlice, 0])
                cube([thickness-verticalSlice, nutWidth, overhangZ + thickness]);

            // Middle piece -- slice a bit off the bottom if sliceBottom is set (for
            // the top piece)
            midThickness = sliceBottom == 0 ? thickness : overhangZ + thickness;
            translate([nutWidth+thickness+extraWidth, 0, 0]) union() {
                cube([middleWidth, nutWidth, midThickness]);
            }

            // Vertical part
            translate([nutWidth + thickness + middleWidth + extraWidth, 0])
                cube([thickness-verticalSlice, nutWidth, overhangZ + thickness]);

            translate([nutWidth + thickness + middleWidth + extraWidth, 0, overhangZ])
                cube([extraWidth+thickness, nutWidth, thickness]);

            translate([nutWidth + 2*thickness + middleWidth + 2*extraWidth, 0, overhangZ]) {
                squareWithHole(nutWidth, holeDiameter, thickness);
            }

            if (screwHeadHeight != 0)
                translate([nutWidth+extraWidth, 0, overhangZ+thickness]) cube([2*thickness+middleWidth, nutWidth, screwHeadHeight]);
        }
    }
}

// TODO: account for screw length
module topPart(nutHeight, nutWidth, holeDiameter, label, screwHeadHeight, screwLength) {
    difference() {
        // Slice off 0.2mm on the bottom to hold the steel, and 0.1mm on the
        // sides to fit the bottom part
        commonPart(nutHeight=nutHeight,
                   nutWidth=nutWidth,
                   holeDiameter=holeDiameter,
                   label=str(label, " - ", "TOP"),
                   middleWidth=middleWidth-2*thickness,
                   extraWidth=thickness,
                   sliceBottom=0.2,
                   verticalSlice=0.1,
                   screwHeadHeight=screwHeadHeight,
                   screwLength=screwLength
            );
    }
}

module bottomPart(nutHeight, nutWidth, holeDiameter, label) {
    commonPart(nutHeight,
               nutWidth,
               holeDiameter,
               str(label, " - ", "BOTTOM"),
               bottomPlate=thickness
        );
}

module bothParts(nutHeight, nutWidth, holeDiameter, label, screwLength, screwHeadHeight=0) {
    // Add 0.1mm tolerance to nutHeight in case it won't fit
    newNutHeight = nutHeight + 0.1;
    translate([0, 0, 0]) {
        rotate([-90, 0]) bottomPart(newNutHeight, nutWidth, holeDiameter, label);
        translate([30, 0, 0]) {
            rotate([-90, 0]) topPart(newNutHeight, nutWidth, holeDiameter, label, screwHeadHeight, screwLength);
        }
    }
}


// Need 2.9mm hole clearance for M2.5, head size is 4.5
// M2.5 nut is 2mm high (max)
if (Screw_Size == "M2.5")
    bothParts(2, 5, 2.9, "M2.5", screwHeadHeight=1.3, screwLength=6);

// M3 nut height is 2.6, but we need 6mm for threads to go through
// need 3.4mm hole clearance for M3, head size is 5.5
if (Screw_Size == "M3")
    bothParts(2.6, 6, 3.4, "M3", screwHeadHeight=2.3, screwLength=6);
