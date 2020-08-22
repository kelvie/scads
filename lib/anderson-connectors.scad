include <BOSL2/std.scad>

module _mirror_copy(n) {
    children(0);
    mirror(n) children(0);
}


// TODO: don't chamfer top (or even use negative chamfers) so it connects better?

// Creates a holder for a pair of Anderson PowerPole 15/45 connectors.
//
// Parameters:
//
//   `middlePin` will determine whether or not to create a middle pin (if false,
//       a hole will be created instead)
//
//   `tolerance` is the amount of tolerance. It is added to the main cutout as
//       well as subtracted from the pins' diameters
//
//   `dovetailLeft` will only create a cutout for the dovetail on the left side
//       if set to true, otherwise both are cut. If you want a dovetail cutout
//       for the right side, simply use `mirror(LEFT)`
//
//   `jack` will make this a housing for a jack (the mated portion of the
//       connector is covered)
//
//   `wall` is the minimum thickness of the walls generated
module pp15_casing(middlePin=true, tolerance=0.2, dovetailLeft=true, jack=false, wall=2, anchor=CENTER) {
    // These are from the official drawings for the 1237 series
    width = 7.9; // x and y
    widthWithDovetail = 8.4; // x
    rollPinRadius = 1.3;
    tipToRollPinCentre = 9.9; // y
    fullLength = 24.6; // y
    wireHoleWidth = 5; // x
    dovetailHeight = 12.3; // y
    matedFullLength = 41.2; // y

    dovetailWidth = widthWithDovetail - width;
    housingLength = jack ? fullLength : matedFullLength - fullLength;

    insideSz = [2*widthWithDovetail, housingLength, widthWithDovetail];
    outsideSz = insideSz + wall * [2, 1, 1] + tolerance * [1, 1, 1];

    chamfer = wall / 3;

    $eps = wall / 100;

    pinR = rollPinRadius - tolerance/2;

    // Left+right walls
    leftWallThickness = wall;
    rightWallThickness = dovetailLeft ? wall + dovetailWidth : wall;

    module make() {
        // left wall
        left(outsideSz.x/2)
            cuboid(
                size=[leftWallThickness, outsideSz.y, outsideSz.z],
                anchor=BOTTOM+BACK+LEFT,
                chamfer=chamfer
                );

        right(outsideSz.x/2)
            cuboid(
                size=[rightWallThickness, outsideSz.y, outsideSz.z],
                anchor=BOTTOM+BACK+RIGHT,
                chamfer=chamfer
                );


        // Add thickness for sides that don't have a dovetail sticking out
        _mirror_copy(LEFT)
            left(outsideSz.x / 2)
            cuboid(size=[wall + dovetailWidth, outsideSz.y - dovetailHeight - wall, outsideSz.z],
                   anchor=BOTTOM+BACK+LEFT,
                   chamfer=chamfer
                );

        // Bottom wall
        difference() {
            cuboid(
                size=[outsideSz.x, outsideSz.y, wall],
                chamfer=chamfer,
                anchor=BOTTOM+BACK,
                edges=edges("ALL")
                );

            // Draw an icon indicating which side to put in the connectors
            if (dovetailLeft)
                up(wall - 0.4 + $eps) fwd(outsideSz.y-dovetailHeight / 2)
                    linear_extrude(0.4) import("icons/pp15-dovetail-left.svg", center=true);


            // If there's no built-in middle roll pin, we cut out a hole instead
            if (!middlePin)
                fwd(rollPinYOffset)
                    down($eps)
                    cyl(r=rollPinRadius + tolerance / 2, h=outsideSz.z+2*$eps, anchor=BOTTOM);
        }

        rollPinYOffset = tipToRollPinCentre - fullLength + housingLength;

        // Side roll pins
        fwd(rollPinYOffset) {
            _mirror_copy(LEFT) left(width)
                cyl(r=pinR, h=outsideSz.z, chamfer=chamfer, anchor=BOTTOM);

            // Optional middle roll pin
            if (middlePin)
                cyl(r=pinR, h=outsideSz.z, chamfer=chamfer, anchor=BOTTOM);

        }

        // Add a back wall for the wire holes
        wireHoleWallWidth = (width - wireHoleWidth) / 2;
        fwd(outsideSz.y) _mirror_copy(LEFT) left(outsideSz.x/2)
            cuboid(size=[wireHoleWallWidth+wall, wall, outsideSz.z],
                   anchor=FRONT+BOTTOM+LEFT,
                   chamfer = chamfer
                );
    }

    attachable(anchor=anchor, size=outsideSz) {
        down(outsideSz.z/2) make();
        children();
    }
}
