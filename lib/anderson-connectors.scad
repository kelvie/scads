include <BOSL2/std.scad>
include <BOSL2/joiners.scad>

// To show a sample
Show_sample = false;

Part_to_show = "Cover"; // [Cover, Base, Mask, All]

/* [Hidden] */
$fa = $preview ? 10 : 5;
$fs = 0.025;

default_wall = 2;
default_tolerance = 0.2;
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

dovetail_insert_hole_tolerance = 2*default_tolerance * [2,1,0];

function _get_inside_size(jack=false) =
    let (housingLength = jack ? fullLength : matedFullLength - fullLength)
    [2*widthWithDovetail, housingLength, widthWithDovetail];

function _get_outside_size(isz, wall=default_wall, tolerance=default_tolerance) =
    isz + wall * [2, 1, 2] + tolerance * [1, 0, 1];

function pp15_get_center_yoffset(jack=false, wall=default_wall,
                                tolerance=default_tolerance) =
    let (
         osz = _get_outside_size(_get_inside_size(jack), wall, tolerance)
         )
    (osz.y - wall - matedFullLength/2);

// TODO: add text argument
// TODO: some way to cut out an entry path for the other connector rather than
//       having it stick out (graduated thickness?)
// TODO: make all variables camelcase
// TODO: chamfer the mask

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
//   `wireHider` if set to true will add a part to the back that hides the wires
//
//   `anchor`, `spin`, and `orient` have their normal meanings within BOSL2 (see
//       attachments.scad)
//
//   `mask` when nonzero creates a cutout mask of the specified height, suitable
//          for cutting openings to mount this onto
module pp15_casing(middlePin=true, tolerance=default_tolerance,
                   dovetailLeft=true, jack=false, wall=default_wall,
                   wireHider=true, mask=0, wirehider_mask=0,
                   anchor=CENTER, spin=0, orient=UP) {

    housingLength = jack ? fullLength : matedFullLength - fullLength;

    insideSz = _get_inside_size(jack);
    outsideSz = _get_outside_size(insideSz, wall, tolerance);

    wireHiderWidth = wireHider ? outsideSz.z : 0;

    fullOutsideSz = outsideSz + (matedFullLength-housingLength+wall)*[0,1,0] +
        wireHiderWidth*[0,2,0];

    chamfer = wall / 3;
    rounding = wall / 2;
    edge_nochamf = wireHider ? [TOP, FRONT] : [TOP];

    $eps = wall / 100;

    pinR = rollPinRadius - tolerance/2;

    // Left+right walls
    leftWallThickness = wall;
    rightWallThickness = dovetailLeft ? wall + dovetailWidth : wall;
    has_mask = mask > 0 || wirehider_mask > 0;
    rollPinYOffset = tipToRollPinCentre - fullLength + housingLength;
    rollPinHeight = widthWithDovetail + tolerance + wall;

    module make_dovetail(type, length, width=2, taper=3) {
        slop=0.05;

        module create_mask() {
            newlength = length;
            right((newlength - length)/2)
                yrot(180) dovetail(type == "male" ? "female" : "male",
                                   length=newlength,
                                   height=wall,
                                   width=width + (newlength - length)*tan(taper),
                                   spin=90,
                                   chamfer=wall/8,
                                   anchor=BOTTOM,
                                   taper=taper, $slop=slop, extra=0) {
                // Needs more tolerance, still hard to put in and out; needs to be wider
                position(FRONT)
                    cuboid($parent_size + dovetail_insert_hole_tolerance,
                           anchor=BACK);
            }
        }

        dovetail(type,
                 length=length,
                 height=wall,
                 width=2,
                 spin=90,
                 chamfer=wall/8,
                 anchor=BOTTOM,
                 taper=taper,
                 $slop=slop, extra=0);

        if (mask > 0) tags("mask") create_mask();

        // For debugging
        // % create_mask();
    }

    module make() {
        // cutouts to show connectors
        % recolor("#ff000033") fwd(outsideSz.y - wall) up(wall)
            cuboid(
                size=[widthWithDovetail, fullLength, widthWithDovetail],
                anchor=FRONT+BOTTOM+LEFT,
                $color="#ff000033"

                );
        % recolor("#00000033") fwd(outsideSz.y - wall) up(wall)
              cuboid(
                  size=[widthWithDovetail, fullLength, widthWithDovetail],
                  anchor=FRONT+BOTTOM+RIGHT
                  );

        // left wall
        left(outsideSz.x/2)
            cuboid(
                size=[leftWallThickness, outsideSz.y, outsideSz.z],
                anchor=BOTTOM+BACK+LEFT,
                rounding=rounding,
                edges=edges("ALL", except=edge_nochamf)
                ) {

            left((leftWallThickness - wall)/2) attach(TOP) {
                fwd((outsideSz.y - wall)/2) make_dovetail("male", wall);
                back((outsideSz.y - wall - chamfer)/2) make_dovetail("male", wall);
            }
        }

        // right wall, with connectors on the back
        right(outsideSz.x/2)
            cuboid(
                size=[rightWallThickness, outsideSz.y, outsideSz.z],
                anchor=BOTTOM+BACK+RIGHT,
                rounding=rounding,
                edges=edges("ALL", except=edge_nochamf)
                ) {
        right((rightWallThickness - wall)/2)
            attach(TOP) {
            fwd((outsideSz.y - wall)/2)
                make_dovetail("male", wall);
            back((outsideSz.y - wall - chamfer)/2)
                make_dovetail("male", wall);
            }
        }

        // Add thickness for sides that don't have a dovetail sticking out
       mirror_copy(LEFT)
            left(outsideSz.x / 2)
            cuboid(size=[wall + dovetailWidth, outsideSz.y - dovetailHeight - wall, outsideSz.z],
                   anchor=BOTTOM+BACK+LEFT,
                   rounding=rounding,
                   edges=edges("ALL", except=edge_nochamf)
                );

        // Bottom wall
        if (attachment_is_shown($tags)) // to workaround weird diff bugs
            difference() {
            cuboid(
                size=[outsideSz.x, outsideSz.y, wall],
                rounding=rounding,
                anchor=BOTTOM+BACK,
                edges=edges("ALL", except=wireHider ? FRONT : [])
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

        // Side roll pins
        fwd(rollPinYOffset) {
            mirror_copy(LEFT) left(width)
                cyl(r=pinR, h=rollPinHeight, chamfer=chamfer, anchor=BOTTOM);

            // Optional middle roll pin
            if (middlePin)
                cyl(r=pinR, h=rollPinHeight, chamfer=chamfer, anchor=BOTTOM);

        }

        // Add a back wall for the wire holes
        wireHoleWallWidth = (width - wireHoleWidth) / 2;
        fwd(outsideSz.y) mirror_copy(LEFT) left(outsideSz.x/2)
            cuboid(size=[wireHoleWallWidth+wall, wall, outsideSz.z],
                   anchor=FRONT+BOTTOM+LEFT,
                   rounding=rounding,
                   edges=edges("ALL", except=edge_nochamf)
                );

        // wire hider cube
        module wh_cube() {
            cuboid(size=[outsideSz.x, outsideSz.z, outsideSz.z],
                   anchor=BACK+BOTTOM)
                tags("children") children();
        }


        if (!has_mask && wireHider) {
            diag = wireHiderWidth * sqrt(2);
            diag_nowall = diag - wall * sqrt(2);
            diag_rounding = rounding/sqrt(2);

            fwd(outsideSz.y)
                difference() {
                intersection() {
                    wh_cube();
                    show("children") wh_cube() {
                        attach(TOP+BACK)
                                  cuboid(size=[outsideSz.x + 0.01, diag+2*rounding, diag],
                               rounding=diag_rounding);
                    }
                }
                show("children") wh_cube() {
                    attach(TOP+BACK)
                        cuboid(size=[outsideSz.x-2*wall, diag_nowall , diag_nowall]);
                }
            }
        }

        if (wirehider_mask != 0) {
            offset = wall;
            tags("wire-hider-mask")
                fwd(outsideSz.y + offset)
                up(outsideSz.z+wirehider_mask)
                    cuboid(size=[insideSz.x, insideSz.z, wirehider_mask + 0.01],
                           anchor=BACK+TOP);
        }

    }

    attachable(anchor=anchor, spin=spin, orient=orient, size=fullOutsideSz) {
        union() {
            down(outsideSz.z/2)
            back(pp15_get_center_yoffset(jack, wall, tolerance))
                if (mask == 0 && wirehider_mask == 0) {
                    hide("mask wire-hider-mask") make();
                } else {
                    show(str(
                             (mask > 0 ? "mask" : ""),
                             " ",
                             (wirehider_mask > 0 ? "wire-hider-mask" : "")
                             ))
                        make($tags="notmask");
                }

            // For debugging
            // % cuboid(fullOutsideSz);
        }
        children();
    }
}

module pp15_casing_wirehider_mask(mask, tolerance=0.1,
                                  wall=default_wall,
                                  anchor=CENTER, spin=0, orient=UP) {
    pp15_casing(
        tolerance=tolerance,
        wall=wall,
        anchor=anchor, spin=spin, orient=orient, wirehider_mask=mask);
}

module pp15_base_plate(wall=2, tolerance=default_tolerance,
                       anchor=CENTER, spin=0, orient=UP) {
    chamf = undef;
    isz = _get_inside_size();
    osz = _get_outside_size(isz);
    yoff = pp15_get_center_yoffset();

    size = [isz.x - 2*(wall + dovetail_insert_hole_tolerance.x),
            osz.y,
            wall];
    bbox_size=[osz.x, 2*(osz.y + abs(yoff)), wall];

    module _part() {
        prismoid(size2=[size.x, size.y], size1=[size.x - 2*size.z, size.y],
                 h=size.z, anchor=CENTER);
    }

    attachable(size=bbox_size, anchor=anchor, spin=spin, orient=orient) {
        union() {
            back(yoff - osz.y/2) _part();
            // debug
            // % cuboid(bbox_size);
        }
        children();
    }
}

if (Show_sample) {
    part = Part_to_show;
    if (part == "Base") {
        pp15_base_plate();
    } else if (part == "All") {
        pp15_base_plate(anchor=TOP);
        pp15_casing(anchor=TOP);
        % pp15_casing(anchor=TOP, mask=3);
    } else if (part == "Mask") {
        pp15_casing(anchor=TOP, mask=3);
    } else if (part == "Cover") {
        pp15_casing(anchor=TOP);
    }

 }
