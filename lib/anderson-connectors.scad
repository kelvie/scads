include <BOSL2/std.scad>
include <BOSL2/hull.scad>
include <BOSL2/joiners.scad>
include <text.scad>
include <add-base.scad>
use <fasteners.scad>

Wire_hider = true;
// Show shapes for debugging purposes
Debug_shapes = true;

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

function _get_outside_size(isz=_get_inside_size(), wall=default_wall, tolerance=default_tolerance) =
    isz + wall * [2, 1, 2] + tolerance * [1, 0, 1];

function pp15_get_inside_size(jack=false) = _get_inside_size(jack=jack);
function pp15_get_outside_size(jack=false, tolerance=default_tolerance) =
    _get_outside_size(isz=pp15_get_inside_size(jack=jack),
                      tolerance=tolerance);

function pp15_get_center_yoffset(jack=false, wall=default_wall,
                                tolerance=default_tolerance) =
    let (
         osz = _get_outside_size(_get_inside_size(jack), wall, tolerance)
         )
    (osz.y - wall - matedFullLength/2);

// TODO: make all variables camelcase
// TODO: add wire hider suitable for a cable end

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
//   `wirehider` if set to true will add a part to the back that hides the wires
//
//   `anchor`, `spin`, and `orient` have their normal meanings within BOSL2 (see
//       attachments.scad)
//
//   `mask` when nonzero creates a cutout mask of the specified height, suitable
//          for cutting openings to mount this onto
//
//   `legs` can be "BOTH", "LEFT", "RIGHT", or "NONE" (default "BOTH")
//
//   `real_size` when set to true uses the actual object size rather than two
//       mated connectors, useful for when you want to attach things
//
//   `half_height_pins` makes it so the roll pins will be half the size, so
//       something else can slot into the other side
module pp15_casing(middlePin=true, tolerance=default_tolerance,
                   dovetailLeft=true, jack=false, wall=default_wall,
                   wirehider=true, mask=0, wirehider_mask=0,
                   anchor=CENTER, spin=0, orient=UP, text, rounding=default_wall/2,
                   leg_height, legs="BOTH", real_size=false, side_grip=false,
                   half_height_pins=false
                   ) {

    housingLength = jack ? fullLength : matedFullLength - fullLength;

    insideSz = _get_inside_size(jack);
    outsideSz = _get_outside_size(insideSz, wall, tolerance);
    real_outside_sz = outsideSz - (legs == "NONE" ? wall * UP : [0,0,0]);

    wireHiderWidth = wirehider ? outsideSz.z : 0;

    fullOutsideSz = outsideSz + (matedFullLength-housingLength+wall)*[0,1,0] +
        wireHiderWidth*[0,2,0];

    chamfer = wall / 3;
    edge_nochamf = wirehider ? [TOP, FRONT] : [TOP];

    $eps = $fs/4;

    pin_r = rollPinRadius - tolerance/2;

    // Left+right walls
    leftWallThickness = wall;
    rightWallThickness = dovetailLeft ? wall + dovetailWidth : wall;
    has_mask = mask > 0 || wirehider_mask > 0;
    rollPinYOffset = tipToRollPinCentre - fullLength + housingLength;
    rollPinHeight = half_height_pins ?
        widthWithDovetail / 2 + wall :
        widthWithDovetail + tolerance + wall;

    // Aka the legs
    module make_dovetail(type, length, width=4, taper=3) {
        slop=0.05;
        leg_height = is_undef(leg_height) ? wall : leg_height;
        module create_mask() {
            newlength = length;
            right((newlength - length)/2)
                yrot(180) dovetail(type == "male" ? "female" : "male",
                                   length=newlength,
                                   height=leg_height,
                                   width=width + (newlength - length)*tan(taper),
                                   spin=90,
                                   chamfer=leg_height/8,
                                   anchor=BOTTOM,
                                   taper=taper, $slop=slop, extra=0) {
                position(FRONT)
                    cuboid($parent_size + dovetail_insert_hole_tolerance,
                           anchor=BACK);
            }
        }

        dovetail(type,
                 length=length,
                 height=leg_height,
                 width=width,
                 spin=90,
                 chamfer=leg_height/8,
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

        // If wall doesn't have legs, remove the extra wall spacing, since this
        // won't attach to anything anyway
        left_wall_h = outsideSz.z - (legs == "BOTH" || legs == "LEFT" ? 0 : wall);
        left_wall_edges = legs == "BOTH" || legs == "LEFT" ? edges("ALL", except=edge_nochamf) : edges("ALL");

        right_wall_h = outsideSz.z - (legs == "BOTH" || legs == "RIGHT" ? 0 : wall);
        right_wall_edges = legs == "BOTH" || legs == "RIGHT" ? edges("ALL", except=edge_nochamf) : edges("ALL");

        module _grips() {
            ycopies(n=4, spacing=wall)
                hull()
                mirror_copy(DOWN)
                down(wall)
                position(TOP)
                spheroid(d=wall/2);
        }
        // left wall
        left(outsideSz.x/2)
            cuboid(
                size=[leftWallThickness, outsideSz.y, left_wall_h],
                anchor=BOTTOM+BACK+LEFT,
                rounding=rounding,
                edges=left_wall_edges
                ) {

            if (is_def(text))
                attach(LEFT) label(text);

            if (side_grip)
                position(LEFT)
                    _grips();

            if (legs == "BOTH" || legs == "LEFT")
                left((leftWallThickness - wall)/2) attach(TOP) {
                    fwd((outsideSz.y - 2*wall)/2)
                        make_dovetail("male", wall);
                    back((outsideSz.y - 2*wall - 2*rounding)/2)
                        make_dovetail("male", wall);
                }
        }

        // right wall, with connectors on the back
        right(outsideSz.x/2)
            cuboid(
                size=[rightWallThickness, outsideSz.y, right_wall_h],
                anchor=BOTTOM+BACK+RIGHT,
                rounding=rounding,
                edges=right_wall_edges
                ) {
            if (is_def(text))
                attach(RIGHT) label(text);

            if (side_grip)
                position(RIGHT)
                    _grips();

            if (legs == "BOTH" || legs == "RIGHT")
                right((rightWallThickness - wall)/2)
                    attach(TOP) {
                    fwd((outsideSz.y - 2*wall)/2)
                        make_dovetail("male", wall);
                    back((outsideSz.y - 2*wall - 2*rounding)/2)
                        make_dovetail("male", wall);
                }
        }

        // Add thickness for sides that don't have a dovetail sticking out
        module _xtra_thicc(height, edges) {
            left(outsideSz.x / 2)
                cuboid(size=[wall + dovetailWidth, outsideSz.y - dovetailHeight - wall, height],
                       anchor=BOTTOM+BACK+LEFT,
                       rounding=rounding,
                       edges=edges
                       );
        }

        _xtra_thicc(left_wall_h, left_wall_edges);
        mirror(LEFT) _xtra_thicc(right_wall_h, right_wall_edges);


        // Add a back wall for the wire holes
        module _back_wall(height, edges) {
            wireHoleWallWidth = (width - wireHoleWidth) / 2;
            fwd(outsideSz.y) left(outsideSz.x/2)
                cuboid(size=[wireHoleWallWidth+wall, wall, height],
                       anchor=FRONT+BOTTOM+LEFT,
                       rounding=rounding,
                       edges=edges
                       );
        }
        _back_wall(left_wall_h, left_wall_edges);
        mirror(LEFT) _back_wall(right_wall_h, right_wall_edges);

        // Bottom wall
        if (attachment_is_shown($tags)) // to workaround weird diff bugs
            difference() {
            cuboid(
                size=[outsideSz.x, outsideSz.y, wall],
                rounding=rounding,
                anchor=BOTTOM+BACK,
                edges=edges("ALL", except=wirehider ? FRONT : [])
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
                cyl(r=pin_r, h=rollPinHeight, chamfer=chamfer, anchor=BOTTOM);

            // Optional middle roll pin
            if (middlePin)
                cyl(r=pin_r, h=rollPinHeight, chamfer=chamfer, anchor=BOTTOM);

        }

        // wire hider cube
        module wh_cube() {
            cuboid(size=[outsideSz.x, outsideSz.z+rounding, outsideSz.z],
                   anchor=BACK+BOTTOM, rounding=rounding,
                   edges=edges(BOTTOM, except=[FRONT, BACK]))
                tags("children") children();
        }


        if (!has_mask && wirehider) {
            diag = wireHiderWidth * sqrt(2);
            diag_nowall = diag - wall * sqrt(2);

            fwd(outsideSz.y)
                difference() {
                intersection() {
                    wh_cube();
                    show("children") wh_cube() {
                        back(outsideSz.z - rounding/2)
                            xrot(-45)
                            cuboid(size=[outsideSz.x, 3*diag, diag],
                                   rounding=rounding);
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

    attachable(anchor=anchor, spin=spin, orient=orient,
               size=real_size ? real_outside_sz : fullOutsideSz) {
        union() {

            down(real_size ? real_outside_sz.z / 2 : outsideSz.z/2)
                back(real_size ? outsideSz.y/2 : pp15_get_center_yoffset(jack, wall, tolerance))
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
            // %cuboid(pp15_get_outside_size(jack=false));
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

module pp15_multi_holder_casing(wall=default_wall, anchor=CENTER, spin=0, orient=TOP) {
    casing_wall = wall;
    pp15_casing(wirehider=false, spin=spin, orient=orient, anchor=anchor,
                wall=casing_wall, rounding=casing_wall/2);
}

module pp15_multi_holder_cutout(t, n=3, width=55, wall=default_wall,
                                tolerance=default_tolerance,
                                anchor=CENTER, spin=0, orient=TOP) {
    isz = _get_inside_size(jack=false);
    osz = _get_outside_size(isz, wall=wall);
    inner_width = width-osz.z - 2*wall;

    size = [inner_width+wall, t, osz.x+wall];

    eps=$fs/4;
    rounding=wall/4;

    // Extra rounding for chamfers
    spacing = osz.z + wall + tolerance;

    module _part() {
        xcopies(n=n, spacing=spacing)
            prismoid(size1=[isz.z, isz.x] + wall * [1,1],
                     size2=[isz.z, isz.x] + wall*2/3 * [1,1],
                     rounding=t/4,
                     h=t+2*eps, orient=BACK, center=true);
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

// TODO: move out of library? This is a separate part to print, but it shares a
// bunch of functions still.
module pp15_multi_holder(n=3, width=55, wall=default_wall, anchor=CENTER,
                         spin=0, orient=TOP, tolerance=default_tolerance) {
    casing_wall = wall;

    isz = _get_inside_size(jack=false);
    osz = _get_outside_size(isz, wall=casing_wall);
    size = [width, osz.y+2*wall + 2*tolerance, osz.x + wall];

    rounding=wall/4;

    inner_width = width-osz.z - 2*wall;
    // Extra rounding for chamfers
    spacing = osz.z + wall + tolerance;

    module _debug_tolerance() {
        % if (Debug_shapes)
            position(LEFT)
                cuboid(size=[tolerance, $parent_size.y, $parent_size.z], anchor=RIGHT);
    }
    module _part() {
        % back(- pp15_get_center_yoffset() + osz.y/2)
            xcopies(n=n, spacing=spacing) {
            up(osz.x/2)
                zrot(180) pp15_casing(orient=RIGHT, wirehider=false,
                                      legs="RIGHT",
                                      spin=180, wall=casing_wall, rounding=casing_wall/2);

        }

        xcopies(n=n, spacing=spacing) {
            difference()  {
                left(osz.z/2)
                    down(wall)
                    cuboid(size=[wall, size.y, osz.x + wall],
                           rounding=rounding,
                           anchor=RIGHT+BOTTOM) {
                    _debug_tolerance();
                };

                back(- pp15_get_center_yoffset() + osz.y/2)
                    up(osz.x/2)
                    zrot(180) pp15_casing(orient=RIGHT, spin=180, mask=3,
                                          wall=casing_wall,
                                          // rounding=casing_wall/2,
                                          wirehider=false, legs="RIGHT");

            }
            back(- pp15_get_center_yoffset() + osz.y/2)
                left(osz.z/2)
                up(osz.x/2)
                zrot(180)
                pp15_base_plate(orient=RIGHT, spin=180, anchor=TOP, wall=casing_wall);
        }
        right(n*spacing/2 + tolerance/2)
            down(wall)
            cuboid(size=[wall, size.y, osz.x + wall],
                   rounding=rounding,
                   anchor=BOTTOM) {
            _debug_tolerance();
        }

        // Bottom plate
        cuboid([width, size.y, wall],
               rounding=rounding,
               anchor=TOP) {

            // Small wall on the front and back to prevent movement
            // TODO: add grooves here to prevent cupping (in the back?)
            mirror_copy(BACK)
                position(FRONT+BOTTOM)
                cuboid([n*spacing+wall, wall, 2*wall],
                       anchor=FRONT+BOTTOM, rounding=rounding);
            // Add rails for nuts
            mirror_copy(LEFT)
                position(LEFT+BOTTOM)
                m3_sqnut_rail(l=min(size.y, 3*m3_screw_head_width()),
                              wall=1.5, rounding=rounding,
                              edges=edges("ALL", except=FRONT),
                              chamfer=1/3, spin=90, anchor=BOTTOM+BACK,
                              orient=TOP, backwall=true, extra_h=size.z/4) {
                // TODO: assert if the wall intersects this
                if (Debug_shapes)
                    % position(TOP) cuboid(size=[size.y+2, 2.4 + tolerance, 5.5 ], anchor=TOP);
            }
        }
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        union() {
            down(osz.x/2 -wall/2) _part();

            // Debug
            // %cuboid(size);
        }
        children();
    }
}

// TODO:
//  - back part doesn't really stay together, needs a clip or something
//  - small line on the inside between tapered part and the casing
//  - torus for wire sticks out a bit
// Requires two parts -- mirror in any direction to get the other part.
module pp15_cable_connector(wire_width=5.1, h=10, wires=1,
                            anchor=CENTER, spin=0, orient=TOP,
                            wall=default_wall) {
    eps=$fs/4;
    tolerance = 0.1;

    rounding = wall/2;
    module _corner(anchor=CENTER) {
        // Needs to be "octa" because we're hulling these, otherwise the hulled
        // walls will be a bit thinner
        spheroid(d=wall, anchor=anchor, style="octa");
    }

    module _wire_hole(extra_od=0) {
        up(wall/2)
            fwd(h)
            mirror_copy(DOWN)
            up((wires - 1) * (wire_width+default_tolerance)/2)
            top_half()
            torus(id=wire_width, od=wire_width+2*wall+extra_od, orient=FRONT);
    }

    module _front_plate(xoff) {
        // Front wall
        hull() {
            mirror_copy(UP) mirror_copy(RIGHT) position(BOTTOM) up(wall/2) {
                position(LEFT) {
                    fwd(h) right(xoff) _corner(LEFT);
                }
            }
        }
    }

    osz = pp15_get_outside_size(tolerance=tolerance);
    size = [osz.x, osz.y, osz.z/2];

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        up(size.z/2)
            bottom_half()
            down(wall/2)
            pp15_casing(legs="NONE", tolerance=tolerance, jack=false,
                        real_size=true, side_grip=true, wirehider=false,
                        half_height_pins=true) {
            position(FRONT) {
                psz = $parent_size;
                // Interface between the casing and the wire strain relief part has
                // a weird indent, I think due to the fillets or tolerances
                mirror_copy(RIGHT) back(wall/2) {
                    left(psz.x/2)
                        cuboid([wall, 2*wall, psz.z],
                               anchor=LEFT,
                               rounding=rounding,
                               edges=FRONT
                               );


                    position(BOTTOM)
                        up(wall/2)
                        fwd(wall/2)
                        cuboid([psz.x, wall, wall], rounding=rounding, edges=FRONT);
                }

                xoff = (psz.x - wire_width - 2*wall)/2;

                // Side walls for wire part
                mirror_copy(RIGHT) hull() {
                    position(LEFT+TOP) down(wall/2) {
                        right(wall/2)  _corner();
                        fwd(h) right(xoff) _corner(LEFT);
                    }
                    position(LEFT+BOTTOM) up(wall/2) {
                        right(wall/2) _corner();
                        fwd(h) right(xoff) _corner(LEFT);
                    }
                }

                // Bottom wall
                hull() {
                    mirror_copy(RIGHT) position(BOTTOM) up(wall/2) {
                        position(LEFT) {
                            right(wall/2) _corner();
                            fwd(h) right(xoff) _corner(LEFT);
                        }
                    }
                }

                difference() {
                    _front_plate(xoff);
                    hull() _wire_hole(extra_od=eps);
                }

                _wire_hole(-tolerance);
            }
        }
        children();
    }
}
