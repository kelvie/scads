// Customizable, connectable DC power output modules
//
// The idea is that you can connect several of these in series to power a whole
// bunch of DC devices at different voltages using buck converters, from the
// same power source (24V, in my case).


include <lib/BOSL2/hull.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/joiners.scad>

include <lib/anderson-connectors.scad>
include <lib/usb-c.scad>
include <lib/fasteners.scad>
include <lib/wire-hook.scad>
include <lib/add-base.scad>

/* [View options] */
// Which piece to render.
Piece = "All"; // [All, Top with connectors, Bottom, Front, Top, Left connector, Right connector]

// Separate all the parts when viewing All pieces
Explode_parts = true;
Explode_offset = 45; // [0:1:100]

/* [Print Options] */
// Adds a extra base on the bottom to prevent elephant's foot
Add_base = true;


/* [Measurements] */
// Inner dimensions of the enclosure

Predefined_size = "25mm"; // [Custom, 25mm: 25mm wide, 55mm: 55mm wide]

// Only applicable when predefined size is Custom. Keep Y and Z the same if you want them to connect nicely...
Box_dimensions = [50, 70, 40];

Wall_thickness = 2;

// Multiplier of the grill width to space out by
Grill_spacing = 1.25;

// General slop for fits
Slop = 0.1;

// Inner width slop for fitting in PCB holders
Inner_width_slop = 0.4;

// Fit of the dovetails that hold the panels together -- increase to make looser
Dovetail_slop = 0.1; // [0:0.025:0.2]


/* [Front Connector options] */
Opening_type = "USB-C+A"; // [USB-C+A, Anderson PP]


/* [Fastener options] */
Screw_size = 3;
Screw_hole_diameter = 3.2;

// Assumes a countersunk screw
Screw_head_height = 1.65;

Nut_thickness = 2.4;
Nut_width = 5.5;

Rail_angle = 45; // [0:15:90]

/* [Wire hook options] */
Use_wire_hooks = true;

// Number of wires to hold for the back wire hook
Back_wire_hook_wires = 4;
Right_wire_hook_wires = 0;
Left_wire_hook_wires = 0;

Wire_thickness = 2.3;

/* [USB-C+A options] */
// From the bottom inside wall
Bottom_USB_C_port_offset = 9.25;
USB_C_hole_tolerance = 0.75;

// Also from the bottom inside wall
Bottom_USB_A_port_offset = 16;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

$eps = $fs/10;

chamf=Wall_thickness/3;

// https://coolors.co/
palette = ["#e6efe9","#c5f4e0","#c2eaba","#a7c4a0","#8f8389"];

pds = Predefined_size;


common_yz = [0, 80, 45];

// Get the box dimensions
function get_box_dimensions() =
    pds == "Custom" ? Box_dimensions :
    common_yz + [1, 0, 0] * (
        pds == "25mm" ? 25 :
        pds == "55mm" ? 55 :
        0);

bd = get_box_dimensions() + Inner_width_slop * [1,0,0];
wt = Wall_thickness;

module edge_dovetail(type, length, spin=0) {
    dovetail(type,
             length=length,
             height=wt/2,
             width=wt/2,
             chamfer=wt/16,
             spin=spin,
             anchor=BOTTOM,
             back_width = 0.9 * wt/2,
             $slop=Dovetail_slop,
             $tags=type == "female" ? "mask" : $tags);
}

module make_front(anchor=BACK, orient=TOP) {

    cube_size = [bd.x, 0, bd.z] + wt*[0, 1, 0] - Slop*[0.5,0,1];
    diff("diffme")
        cuboid(cube_size,
               anchor=anchor, orient=orient,
               edges=edges("ALL", except=BACK,BOTTOM)) {

        // Dovetails on both sides
        mirror_copy(LEFT) attach(LEFT)
            edge_dovetail("male", cube_size.z);

        // To slot into the bottom plate
        position(BOTTOM+BACK)
            cuboid([$parent_size.x / 2, wt/2, wt/2],
                   anchor=TOP+BACK, chamfer=chamf/2,
                   edges=edges("ALL", except=TOP));

        position(TOP+FRONT)
            m3_sqnut_holder(wall=wt,
                            chamfer=chamf,
                            orient=BACK,
                            anchor=FRONT+BOTTOM);

        tags("diffme") {

            // USB-C hole
            down(bd.z/ 2 - Bottom_USB_C_port_offset)
            usb_c_jack_hole(l=Box_dimensions.y,
                            tolerance=USB_C_hole_tolerance);

            // TODO: make a library for USB-A port
            usb_port_size = [13.2, 6];
            down(bd.z/2 - Bottom_USB_A_port_offset)
                cuboid([usb_port_size.x,
                        Box_dimensions.y,
                        usb_port_size.y] + USB_C_hole_tolerance * [1, 0, 1] ,
                       rounding=0.25);
        }
    }
}

// future TODOs
// TODO: removeable inner plate to swap in and out... this way I can swap this
//       between the buck convertor and this
// TODO: stack 2-up? (need to think about adjustability, or have them easy to
//       slide out)
// TODO: text on side connectors to know which one's which, and what voltages
// TODO: customize front plate
// TODO: split parts into modules rather than use tags...
// TODO: front anderson powerpole holder

// nearterm TODOs:
// - Make top more printable -- have top part detach from bottom part?
// - Deal with warpability of long parts on platform, make bottom plate
//   thicker or use a pattern on the bottom (good for grip anyway), and we'll
//   also need holes anyway
/*
module make_parttt() {

    // Whether or not to cover all the connectors... I don't think this is
    // helpful as it hides the colours.
    connector_jack = false;
    connector_spin = 0;

    module make_wire_hook(width, num_wires=4) {
        if (Use_wire_hooks && num_wires > 0)
            wire_hook(thickness=1,
                      wire_diameter=Wire_thickness,
                      width=width,
                      num_wires=num_wires,
                      anchor=BACK+BOTTOM)
                children();
    }

    // Build around a hidden inner cube
    hide("hidden")
        cuboid(size=bd,
               $overlap=0, $tags="hidden") {

        // Can't colour this because it overrides all children's colouring...
        // recolor(palette[1])
            tags("main") {

                // Debug -- need a screw rail 12mm near the front to fit the USB
                // module
                // %position(FRONT) cuboid([100, 12, 100], anchor=FRONT);
            position(BOTTOM)
                diff("mask", "main")
                cuboid([bd.x, bd.y, 0] + wt*[2,2,1],
                       anchor=TOP, chamfer=chamf,
                       edges=edges("ALL", except=[TOP])) {
                tags("mask") {

                    // cutout for the slot for the front plate
                    back(wt/2 + Slop/2)
                        up($eps)
                        position(FRONT+TOP)
                        cuboid([$parent_size.x / 2, wt/2 + Slop, wt/2 + Slop],
                               anchor=TOP+FRONT,
                               chamfer=chamf/2,
                               edges=edges("ALL", except=TOP));

                    // Rails
                    attach(BOTTOM, $overlap=-$eps)
                        m3_screw_rail_grill(l=$parent_size.y - 2*wt, w=$parent_size.x - 2*wt, h=wt*2);
                }

            }

            // TODO refactor common parts for left + right
            // Left wall
            position(LEFT)
                down(wt/2)
                diff("mask", "main")
                cuboid([0, bd.y, bd.z] + wt*[1,2,1],
                       anchor=RIGHT,
                       chamfer=chamf,
                       edges=edges("ALL", except=[RIGHT, TOP])) {


                // Cut out screw rails
                left($eps) attach(LEFT) {
                    fwd($parent_size.z/4)
                        mirror(LEFT)
                        m3_screw_rail_grill(w=$parent_size.y - 2*wt,
                                            l=$parent_size.z/2 - 2*wt,
                                            h=2*wt, $tags="mask", angle=Rail_angle);

                    back($parent_size.z/4)
                        right($parent_size.y/4 - wt/2)
                        mirror(LEFT)
                        m3_screw_rail_grill(w=$parent_size.y/2 - wt,
                                            l=$parent_size.z/2 - 2*wt,
                                            h=2*wt, $tags="mask",
                                            anchor=TOP, angle=Rail_angle);
            }

                // Dovetails for top
                attach(TOP) edge_dovetail("male", bd.y);

                // Dovetails for front
                up(wt/2)
                fwd(bd.y/2 + wt/2)
                    attach(RIGHT)
                    edge_dovetail("female", bd.z);

                position(LEFT+TOP) {
                    // PP15 connector
                    tags("left-c connector")
                        pp15_casing(jack=false, anchor=TOP+RIGHT,
                                    spin=180 - connector_spin,
                                    orient=RIGHT);

                    // cutout into wall
                    tags("mask")
                        left(0.01) {
                        pp15_casing(jack=false,
                                    anchor=TOP+RIGHT,
                                    spin=180-connector_spin,
                                    orient=RIGHT,
                                    mask=2*wt);

                        hull() {
                            move_copies([CENTER, 2*wt*UP])
                            pp15_casing_wirehider_mask(
                                anchor=TOP+RIGHT,
                                spin=180-connector_spin,
                                orient=RIGHT,
                                mask=2*wt);
                        }
                    }
                }

                // Wire hook
                up($parent_size.z/2 - Slop)
                    attach(RIGHT)
                    make_wire_hook($parent_size.y / 4, Left_wire_hook_wires);

            }

            // Right wall
            position(RIGHT)
                down(wt/2)
                diff("mask", "main")
                cuboid([0, bd.y, bd.z] + wt*[1,2,1],
                       anchor=LEFT,
                       chamfer=chamf,
                       edges=edges("ALL", except=[LEFT, TOP])) {

                // screw rails
                // Cut out screw rails
                right($eps) attach(RIGHT) {
                    fwd($parent_size.z/4)
                        m3_screw_rail_grill(w=$parent_size.y - 2*wt,
                                            l=$parent_size.z/2 - 2*wt,
                                            h=2*wt, $tags="mask", angle=Rail_angle);

                    back($parent_size.z/4)
                        right($parent_size.y/4 - wt/2)
                        m3_screw_rail_grill(w=$parent_size.y/2 - wt,
                                            l=$parent_size.z/2 - 2*wt,
                                            h=2*wt, $tags="mask", anchor=TOP,
                                            angle=Rail_angle);
                }

                // Dovetails for top
                attach(TOP) edge_dovetail("male", bd.y);

                // Dovetails for front
                up(wt/2)
                    fwd(bd.y/2 + wt/2)
                    attach(LEFT)
                    edge_dovetail("female", bd.z);


                position(RIGHT+TOP) {

                    // PP15 connector
                    tags("right-c connector")
                        pp15_casing(jack=connector_jack,
                                    anchor=TOP+RIGHT,
                                    spin=connector_spin,
                                    orient=LEFT);

                    // cutout into wall
                    tags("mask")
                        right(0.01) {
                        pp15_casing(jack=connector_jack,
                                    anchor=TOP+RIGHT,
                                    orient=LEFT,
                                    spin=connector_spin,
                                    mask=3);
                        hull() {
                            move_copies([CENTER, 2*wt*UP])
                                pp15_casing_wirehider_mask(
                                    anchor=TOP+RIGHT,
                                    spin=connector_spin,
                                    orient=LEFT,
                                    mask=2*wt);
                        }
                    }
                }

                up($parent_size.z/2 - Slop)
                    attach(LEFT)
                    make_wire_hook($parent_size.y / 4, Right_wire_hook_wires);
            }

            position(BACK)
                cuboid([bd.x, 0, bd.z] + wt*[2,1,2],
                       anchor=FRONT,
                       chamfer=chamf,
                       edges=edges("ALL", except=[FRONT])) {
                up($parent_size.z/2 - wt - Slop)
                    attach(FRONT)
                    make_wire_hook($parent_size.x / 3, Back_wire_hook_wires);
            }

        }

        tags("top") position(TOP)
            fwd(wt/2)
            make_top();

        tags("front") position(FRONT)
            make_front();
    }
}
*/

// Size of dovetails that fit the bottom to the top piece
back_dovetail_ratio = 1/4;
front_dovetail_ratio = 1/8;

module make_top(anchor=BOTTOM, orient=TOP, spin=0) {
    inner_size = [bd.x, bd.y, bd.z/2];
    size = inner_size + wt*[2,2,1];

    module _right_wall() {
        position(RIGHT+TOP)
            diff("mask")
            cuboid([wt, size.y, size.z],
                   anchor=RIGHT+TOP,
                   chamfer=chamf,
                   edges=edges("ALL", except=[TOP, LEFT])) {

            back_dovetail_ratio = 1/3;

            dovetail_base_l = inner_size.y;

            // Dovetails on bottom (back)
            back(dovetail_base_l * (1 - back_dovetail_ratio)/2)
                attach(TOP)
                edge_dovetail("female", back_dovetail_ratio * dovetail_base_l, spin=180);

            // Dovetails on bottom (front)
            fwd(dovetail_base_l * (1 - front_dovetail_ratio)/2)
                attach(TOP)
                edge_dovetail("male", front_dovetail_ratio*dovetail_base_l);


            // Dovetails for front
            up(wt/2 - inner_size.z/4)
                fwd(bd.y/2 + wt/2)
                attach(LEFT)
                edge_dovetail("male", inner_size.z/2);

            // Cut out notch to fit the bottom part in the back
            position(BACK+TOP)
                back($eps)
                up($eps)
                cuboid([size.x, wt+$eps, wt+$eps], anchor=BACK+TOP, $tags="mask");

            // Add a notch to fit the top part in the front
            position(FRONT+TOP)
                cuboid([wt, wt, wt],
                       chamfer=chamf,
                       edges=edges(RIGHT, except=[TOP, BOTTOM, BACK]),
                       anchor=FRONT+BOTTOM);
            children();
        }
    }

    module _part() {
        // Debug
        // % cuboid(size);
        hide("hidden")
            cuboid(size, $tags="hidden")
            tags("nothidden") {
            position(BOTTOM)
                diff("mask")
                cuboid([size.x, size.y, 0] + wt*[0, 0,1],
                       anchor=BOTTOM, chamfer=chamf,
                       edges=edges("ALL", except=[TOP])) {
                // Grill for screws
                attach(BOTTOM, $overlap=-$eps)
                    m3_screw_rail_grill(l=$parent_size.y - 2*wt,
                                        w=$parent_size.x - 2*wt,
                                        h=wt*2,
                                        angle=Rail_angle,
                                        $tags="mask");
            }

            // left/right walls
            _right_wall() {
                attach(RIGHT, $overlap=-$eps)
                    left(($parent_size.y/2 - wt) / 2)
                    m3_screw_rail_grill(l=$parent_size.z - 2*wt,
                                        w=$parent_size.y/2 - 2*wt,
                                        h=wt*2, angle=Rail_angle,
                                        $tags="mask");
                mirror(FRONT) position(RIGHT+TOP) {
                    // TODO: positioning is wrong, doesn't reach the top
                    // cutout into wall
                    tags("mask")
                        right($eps) {
                        pp15_casing(jack=false,
                                    anchor=TOP+RIGHT,
                                    orient=LEFT,
                                    mask=3);


                        hull()
                            move_copies([CENTER, 2*wt*UP])
                            pp15_casing_wirehider_mask(anchor=TOP+RIGHT,
                                                       orient=LEFT,
                                                       mask=2*wt);
                    }
                }
            }

            mirror(LEFT)
                _right_wall() {
                attach(RIGHT, $overlap=-$eps)
                    right(($parent_size.y/2 - wt) / 2)
                    m3_screw_rail_grill(l=$parent_size.z - 2*wt,
                                        w=$parent_size.y/2 - 2*wt,
                                        h=wt*2, angle=Rail_angle,
                                        $tags="mask");
                position(RIGHT+TOP) {
                    // cutout into wall
                    tags("mask")
                        right($eps) {
                        pp15_casing(jack=false,
                                    anchor=TOP+RIGHT,
                                    orient=LEFT,
                                    mask=3);

                        hull()
                            move_copies([CENTER, 2*wt*UP])
                            pp15_casing_wirehider_mask(anchor=TOP+RIGHT,
                                                       orient=LEFT,
                                                       mask=2*wt);
                    }
                }
            }


            // Back wall
            position(BACK+BOTTOM)
                cuboid([size.x, 0, size.z] + wt * [0, 1, -1],
                       anchor=BACK+BOTTOM,
                       chamfer=chamf,
                       edges=edges("ALL", except=[TOP, FRONT]));
        }
    }

    attachable(size=size, anchor=anchor, orient=orient, spin=spin) {
        _part();
        children();
    }
}

// TODO:
//   - what to do about front?
module make_bottom(anchor=CENTER, orient=TOP, spin=0) {
    inner_size = [bd.x, bd.y, bd.z/2];
    size = inner_size + wt*[2,2,1];

    module _part() {
        // Debug
        // % cuboid(size);
        hide("hidden")
            cuboid(size, $tags="hidden")
            tags("nothidden") {
            position(BOTTOM)
                diff("mask")
                cuboid([size.x, size.y, 0] + wt*[0, 0,1],
                       anchor=BOTTOM, chamfer=chamf,
                       edges=edges("ALL", except=[TOP])) {
                    // Grill for screws
                    attach(BOTTOM, $overlap=-$eps)
                        m3_screw_rail_grill(l=$parent_size.y - 2*wt,
                                            w=$parent_size.x - 2*wt,
                                            h=wt*2,
                                            angle=Rail_angle,
                                            $tags="mask");
            }

            // left/right walls
            mirror_copy(LEFT)
            position(RIGHT+TOP)
                diff("mask")
                cuboid([wt, size.y, size.z],
                       anchor=RIGHT+TOP,
                       chamfer=chamf,
                       edges=edges("ALL", except=[TOP, LEFT])) {
                attach(RIGHT, $overlap=-$eps)
                    m3_screw_rail_grill(l=$parent_size.z - 2*wt,
                                        w=$parent_size.y - 2*wt,
                                        h=wt*2, angle=Rail_angle,
                                        $tags="mask");

                dovetail_base_l = inner_size.y;

                // Dovetail on top (back)
                back(dovetail_base_l * (1 - back_dovetail_ratio)/2)
                    attach(TOP)
                    edge_dovetail("male", back_dovetail_ratio * dovetail_base_l, spin=180);

                fwd(dovetail_base_l * (1 - front_dovetail_ratio)/2)
                attach(TOP)
                    edge_dovetail("female", front_dovetail_ratio*dovetail_base_l);

                // Dovetails for front
                up(wt/2 - inner_size.z/4)
                    fwd(bd.y/2 + wt/2)
                    attach(LEFT)
                        edge_dovetail("male", inner_size.z/2);

                // Cut out a notch on the top+front to fit the top part
                position(FRONT+TOP)
                    up($eps)
                    fwd($eps)
                    cuboid((wt+$eps) * [1, 1, 1],
                           anchor=FRONT+TOP, $tags="mask");

            }
            // Back wall
            position(BACK+BOTTOM)
                cuboid([size.x, 0, size.z] + wt * [0, 1, 1],
                       anchor=BACK+BOTTOM,
                       chamfer=chamf,
                       edges=BOTTOM);
        }
    }

    attachable(size=size, anchor=anchor, orient=orient, spin=spin) {
        _part();
        children();
    }
}

module explode_out(direction) {
    explode_offset = Explode_offset;

    if (Explode_parts && explode_offset > 0) {
        // This creates an outline to the exploded part but it's too distracting
        // % hull() {
        //     children(0);
        //     translate(explode_offset * direction * 0.99) children(0);
        // }
        translate(explode_offset*direction) children(0);
    } else
        children(0);
}

// Optionally show the pieces exploded for "All"
if (Piece == "All") {
    // explode_out(LEFT)
    //     show("left-c") make_part();
    // explode_out(RIGHT)
    //     show("right-c") make_part();


    color(palette[1]) make_bottom(anchor=TOP);

    explode_out(FORWARD)
        color(palette[3], alpha=0.99) make_top(anchor=TOP, orient=BOTTOM);

    explode_out(UP)
        fwd(bd.y/2)
         color(palette[4], alpha=0.99) make_front(anchor=BACK);

 } else if (Piece == "Top with connectors") {
    // show("main connector") make_part();
 } else if (Piece == "Front") {
    // Front is really thin so needs less inset
    add_base(0.3, 0.75, 0.1, enable=Add_base)
        make_front(anchor=TOP, orient=BOTTOM);
 } else if (Piece == "Top") {
    // Top piece can't be printed directly on the platform or it warps during
    // curing
    make_top(anchor=BOTTOM, orient=TOP);
 } else if (Piece == "Bottom") {
    make_bottom(anchor=BOTTOM);
 } else {
    add_base(0.3, 1.5, 0.1, enable=Add_base)
        if (Piece == "Right connector" || Piece == "Left connector") {
            pp15_casing(jack=false, anchor=BOTTOM);
        }
 }

$export_suffix = Piece;
