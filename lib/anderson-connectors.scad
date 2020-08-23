include <BOSL2/std.scad>

module _mirror_copy(n) {
    children(0);
    mirror(n) children(0);
}

// TODO: Negative chamfer / overlap to connect better?
// TODO: some way to cut out an entry path

// Creates a holder for a pair of Anderson PowerPole 15/45 connectors.
//
// Parameters:
//
//   `middlePin` will determine whether or not to create a middle pin (if false,
//       a hole will be created instead)
//
//   `tolerance` is the amount of tolerance. It is subtracted from the roll
//       pins' radii as well as increases the width to fit the connectors. A
//       middlePin will allow you to make the tolerance looser for the same fit.
//
//   `dovetailLeft` will only create a cutout for the dovetail on the left side
//       if set to true, otherwise both are cut. If you want a dovetail cutout
//       for the right side, simply use `mirror(LEFT)`
//
//   `jack` will make this a housing for a jack (the mated portion of the
//       connector is covered)
//
//   `wall` is the minimum thickness of the walls generated
//
//   `anchor`, `spin`, and `orient` have their normal meanings within BOSL2 (see
//       attachments.scad)
//
//   `mask` when nonzero creates a cutout mask of the specified height, suitable
//          for cutting holes to mount this onto
module pp15_casing(middlePin=true, tolerance=0.2, dovetailLeft=true, jack=false, wall=2,
                   anchor=CENTER, spin=0, orient=UP, mask=0) {
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
    outsideSz = insideSz + wall * [2, 1, 2] + tolerance * [1, 0, 1];
    fullOutsideSz = outsideSz + (matedFullLength-housingLength)*[0,1,0];

    chamfer = wall / 3;

    $eps = wall / 100;

    pinR = rollPinRadius - tolerance/2;

    // Left+right walls
    leftWallThickness = wall;
    rightWallThickness = dovetailLeft ? wall + dovetailWidth : wall;

    module make() {
        // cutouts to show connectors
        % color("red", 0.2) fwd(outsideSz.y - wall) up(wall) cuboid(
            size=[widthWithDovetail, fullLength, widthWithDovetail],
            anchor=FRONT+BOTTOM+LEFT
            );
        % color("black", 0.2) fwd(outsideSz.y - wall) up(wall) cuboid(
            size=[widthWithDovetail, fullLength, widthWithDovetail],
            anchor=FRONT+BOTTOM+RIGHT
            );

        // left wall
        left(outsideSz.x/2)
            cuboid(
                size=[leftWallThickness, outsideSz.y, outsideSz.z],
                anchor=BOTTOM+BACK+LEFT,
                chamfer=chamfer,
                edges=edges("ALL", except=TOP)
                );

        right(outsideSz.x/2)
            cuboid(
                size=[rightWallThickness, outsideSz.y, outsideSz.z],
                anchor=BOTTOM+BACK+RIGHT,
                chamfer=chamfer,
                edges=edges("ALL", except=TOP)
                );


        // Add thickness for sides that don't have a dovetail sticking out
        _mirror_copy(LEFT)
            left(outsideSz.x / 2)
            cuboid(size=[wall + dovetailWidth, outsideSz.y - dovetailHeight - wall, outsideSz.z],
                   anchor=BOTTOM+BACK+LEFT,
                   chamfer=chamfer,
                   edges=edges("ALL", except=TOP)
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
        rollPinHeight = widthWithDovetail + tolerance + wall;

        // Side roll pins
        fwd(rollPinYOffset) {
            _mirror_copy(LEFT) left(width)
                cyl(r=pinR, h=rollPinHeight, chamfer=chamfer, anchor=BOTTOM);

            // Optional middle roll pin
            if (middlePin)
                cyl(r=pinR, h=rollPinHeight, chamfer=chamfer, anchor=BOTTOM);

        }

        // Add a back wall for the wire holes
        wireHoleWallWidth = (width - wireHoleWidth) / 2;
        fwd(outsideSz.y) _mirror_copy(LEFT) left(outsideSz.x/2)
            cuboid(size=[wireHoleWallWidth+wall, wall, outsideSz.z],
                   anchor=FRONT+BOTTOM+LEFT,
                   chamfer = chamfer,
                   edges=edges("ALL", except=TOP)
                );
    }

    attachable(anchor=anchor, spin=spin, orient=orient, size=fullOutsideSz) {
        down(fullOutsideSz.z/2)
            back(outsideSz.y - wall - matedFullLength/2)
            if (mask == 0)
                make();
            else {
                sz = [insideSz.x, insideSz.y, mask];
                cuboid(sz, anchor=BOTTOM+BACK);
            }
        children();
    }
}
