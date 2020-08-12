// Wall mounting brackets for my MSI gs40 laptop I converted into a all-in-one

// TODO: angle the backplate for a better viewing angle
// TODO: Make the angle of the infil lines adjustable

// This includes the rubber feet, and any clearances
Laptop_Thickness = 24;

// When putting foam tape on, how much extra thickness to add, will be added
Foam_Tape_Thickness = 1.5;

// Min part thickness
Min_Thickness = 3;

// Distance the laptop should stick out from the wall
Wall_Clearance = 20;

// Size of the corner portion (X-dimension)
Left_Bottom_Length = 40;
Right_Bottom_Length = 28;

Corner_Height = 80;

Screen_Left_Offset = 17;
Screen_Right_Offset = 10;
Screen_Bottom_Offset = 15;

// Angle to taper the screw hole to avoid overhang
Number_of_screw_holes = 2;
Screw_Hole_Taper_Angle = 10;
Screw_Size = 3.65; // [4.35:#8, 3.65:#6]
Screw_Head_Diameter = 9;
Screw_Head_Height = 5;
Screw_Hole_Placement = 3; // [3:inside, 2:center, 1:outside]

Infill_Thickness = 3;
Infill_Spacing = 9;

Fillet_Radius = 0.7;

// min feature size
$fs=0.025;
// angle to render as a single feature in a circle
$fa=3;

// Epsilon for cuts
$eps=0.01;

screwDiameter = Screw_Size;

module fillet2d(r=Fillet_Radius) {
    offset(r=r) offset(delta=-r)
        children(0);
}

// Optionally takes children to cut out of the 2d shape
module baseBox(v, r=Fillet_Radius) {
    mirror([0, 1, 0]) // move to +Y side
        rotate([90, 0]) // Put on XZ plane
        linear_extrude(v.y)
        fillet2d(r)
        difference() {
        square([v.x, v.z]);
        children();
    }
}

newLtThickness = Laptop_Thickness + 2*Foam_Tape_Thickness;

// ============
// Laptop notes
// ============

// Base is about 22mm thick, on the left side there is the plug. Probably want
// to integrate that, it's pretty high up though.

// There needs to be some clearance in the back in order for the cables to run
// through it (and also for cooling), that's what Wall Clearance is for.

// Ideally it'll be angled facing up, but that'll make the bottom part stick out
// much further from the wall than necessary

// To place in, put the laptop down, then left; does this need a hinge? Pull to
// the left, then up, to release. Need to be able to put it in at an angle,
// perhaps something that you push out via a spring, then it locks into place ?


// Creates an infil lattice
module infill(bbox,
              thickness=Infill_Thickness,
              spacing=Infill_Spacing,
              angle=45) {
    $inf = max(bbox.x * 2, bbox.z * 2);

    // Vertical lines, divide into 4, one for each possible position for the
    // screw holes
    for (i = [1:3]) {
        translate([i*bbox.x/4 - thickness/2, 0])
            cube([thickness, bbox.y, $inf]);
    }

    // Angled infill lines
    length = bbox.x/cos(angle);
    zWavelength = (thickness + spacing) / sin(angle);
    // TODO: layer calc only works for angle=45
    layers = ceil((bbox.z + bbox.x) / zWavelength);
    for (i = [0:layers-1]) {
        translate([0, 0, i*zWavelength])
            rotate([0, angle, 0])
            cube([$inf, bbox.y, thickness]);
    }
}

module addScrewHole(center, length,
                    id=screwDiameter,
                    od=Screw_Head_Diameter) {
    l = length;

    // For drawing a cylinder around the inset head region, to make sure we
    // don't go below Min_Thickness at any point
    headExtraOD = od + 2*Min_Thickness;

    rot = [-90, 0, 0];

    module addScrewPillar() {
        union() {
            children(0);
            translate(center)
                rotate(rot) {
                    cylinder(d=headExtraOD, h=Screw_Head_Height);
                    translate([0, 0, Screw_Head_Height])
                        cylinder(d=od, h=l-Screw_Head_Height);
            }

        }
    }
    // Drills a hole for the screw, as well as one for the inset screw head.
    module drillScrewHole() {
        difference() {
            children(0);
            translate(center)
                rotate(rot)
                translate([0,0,-$eps]) {
                cylinder(d=id, h=length+2*$eps);
                cylinder(d=od, h=Screw_Head_Height);
            }
        }
    }

    drillScrewHole()
        addScrewPillar()
        children(0);
}

module makeBottomLeftCorner(sideOffset, bottomLength) {
    // just a big number to do cuts with
    $inf = 100;

    // Make sure the overall X length is enough to contain the extra clearance
    // for screw holes if they are on the inside

    screwHeadClearance = Screw_Head_Diameter + 2*Min_Thickness;
    overallX = max(bottomLength + Foam_Tape_Thickness, screwHeadClearance *2 - Min_Thickness);
    overallY = newLtThickness + Wall_Clearance;
    bbox = [1,1,1] * Min_Thickness +
        [overallX, overallY, Corner_Height + Foam_Tape_Thickness];

    screwHoles = Number_of_screw_holes;

    module addScrewHoles(n) {
        center = [bbox.x / 4 * Screw_Hole_Placement,
                  Min_Thickness + newLtThickness,
                  bbox.z * n /(screwHoles+1)];
        length = Wall_Clearance;
        if (n > 0)
            addScrewHole(center, length)
                addScrewHoles(n-1)
                children(0);
        else
            children(0);
    }

    echo("Screw length: ", Wall_Clearance + Min_Thickness - Screw_Head_Height);

    addScrewHoles(screwHoles)
    intersection() {
        baseBox(bbox);

        union() {
            // back plate
            translate([-$eps, Min_Thickness + newLtThickness, -$eps])
                baseBox([$inf, Min_Thickness, $inf]);

            // front plate
            wallAndFoam = Min_Thickness + Foam_Tape_Thickness;
            baseBox([bottomLength + Foam_Tape_Thickness + Min_Thickness, Min_Thickness, bbox.z])
                translate([sideOffset + wallAndFoam,
                           Screen_Bottom_Offset + wallAndFoam])
                fillet2d() square($inf);

            // left plate
            baseBox([Min_Thickness, bbox.y, bbox.z], r=Fillet_Radius/2);

            // bottom plate
            cube([bbox.x, bbox.y, Min_Thickness]);

            // Cutout for the back portion
            translate([0, 2*Min_Thickness + newLtThickness, 0]) {
                baseBox([bbox.x, Wall_Clearance, bbox.z])
                fillet2d()
                    offset(delta=-Min_Thickness)
                    square([bbox.x, bbox.z]);
                infill([bbox.x, Wall_Clearance, bbox.z]);
            }

            // chamfer for bottom plate + front plate
            difference() {
                translate([0, Min_Thickness, Min_Thickness])
                    cube([bottomLength + wallAndFoam, newLtThickness/2, Screen_Bottom_Offset]);
                translate([0, Min_Thickness, Min_Thickness])
                    mirror([1, 0, 0])
                    rotate([0, -90, 0])
                    linear_extrude(bbox.x + $eps)
                    fillet2d()
                    square([bbox.z, newLtThickness]);
            }

            // chamfer for bottom plate + back plate
            difference() {
                translate([0, Min_Thickness + newLtThickness/2, Min_Thickness])
                    cube([bbox.x, newLtThickness/2, Screen_Bottom_Offset]);
                translate([0, Min_Thickness, Min_Thickness])
                    mirror([1, 0, 0])
                    rotate([0, -90, 0])
                    linear_extrude(bbox.x + $eps)
                    fillet2d()
                    square([bbox.z, newLtThickness]);
            }

         }
    }
}

makeBottomLeftCorner(sideOffset=Screen_Left_Offset, bottomLength=Left_Bottom_Length);

translate([Left_Bottom_Length * 3, 0 ])
    mirror([1, 0, 0])
    makeBottomLeftCorner(sideOffset=Screen_Right_Offset, bottomLength=Right_Bottom_Length);
