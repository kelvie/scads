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
Piece = "All"; // [All, Main with connectors, Main, Front, Top, Side connector]

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
Dovetail_slop = 0.15; // [0:0.025:0.2]


/* [Front Connector options] */
Opening_type = "USB-C+A"; // [USB-C+A, Anderson PP]


/* [Fastener options] */
Screw_size = 3;
Screw_hole_diameter = 3.2;

// Assumes a countersunk screw
Screw_head_height = 1.65;

Nut_thickness = 2.4;
Nut_width = 5.5;


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


common_yz = [0, 80, 40];

// Get the box dimensions
function get_box_dimensions() =
    pds == "Custom" ? Box_dimensions :
    common_yz + [1, 0, 0] * (
        pds == "25mm" ? 25 :
        pds == "55mm" ? 55 :
        0);

bd = get_box_dimensions() + Inner_width_slop * [1,0,0];
wt = Wall_thickness;

module edge_dovetail(type, length) {
    dovetail(type,
             length=length,
             height=wt/2,
             width=wt/2,
             chamfer=wt/16,
             spin=180,
             anchor=BOTTOM,
             back_width = 0.9 * wt/2,
             $slop=Dovetail_slop,
             $tags=$tags
        );
}

hole_d = Screw_hole_diameter;
screw_head_h = Screw_head_height;
screw_head_w = Screw_size + 2*screw_head_h;

module screw_rail(l, h, anchor=CENTER, orient=TOP, spin=0) {
    size = [l + screw_head_w, screw_head_w, h];

    module _cutout() {
        hull()
            mirror_copy(LEFT)
            left(l/2)
            cyl(d=hole_d, h=h);

        hull()
            mirror_copy(LEFT)
            left(l/2)
            up(h/2)
            cyl(d2=screw_head_w,
                d1=Screw_size,
                h=screw_head_h,
                anchor=TOP);
    }

    attachable(size=size, anchor=anchor, orient=orient, spin=spin) {
        _cutout();
        children();
    }
}

// TODO: this is ugly af
module screw_rail_grill(w, l, h, anchor=TOP+LEFT) {
    xcopies(l=w, spacing=Grill_spacing*screw_head_w)
        screw_rail(l=l , h=h, anchor=anchor, spin=90);
}


module make_top(anchor=BOTTOM, orient=TOP) {
    diff("diffme")
        cuboid([bd.x, bd.y, 0] + wt*[2,1,1],
               anchor=anchor, chamfer=chamf, orient=orient,
               edges=edges("ALL", except=[BACK, BOTTOM])) {
        attach(BOTTOM) {
            mirror_copy(LEFT)
                left($parent_size.x/2 - wt/2)
                back(wt/2)
                edge_dovetail("female", bd.y, $tags="diffme");
        }
        back(wt + Nut_width/2 - Slop/2)
            up($eps)
            position(TOP+FRONT)
            screw_rail(l=0, h=2*wt, anchor=TOP, $tags="diffme");
    }
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
// TODO: Bottom rail?
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
module make_part() {

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
                // cutout for the slot for the front plate
                tags("mask")
                back(wt/2 + Slop/2)
                    up($eps)
                    position(FRONT+TOP)
                    cuboid([$parent_size.x / 2, wt/2 + Slop, wt/2 + Slop],
                           anchor=TOP+FRONT,
                           chamfer=chamf/2,
                           edges=edges("ALL", except=TOP));

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
                    fwd($parent_size.z/2 - wt)
                        screw_rail_grill(w=$parent_size.y - 2*screw_head_w,
                                         l=$parent_size.z/4 - wt,
                                         h=2*wt, $tags="mask");

                    back($parent_size.z/2 - wt)
                        right($parent_size.y/4 - wt/2)
                        screw_rail_grill(w=($parent_size.y - 2*screw_head_w)/2,
                                         l=$parent_size.z/4 - wt,
                                         h=2*wt, $tags="mask", anchor=TOP+RIGHT);
                }

                // Dovetails for top
                attach(TOP) edge_dovetail("male", bd.y);

                // Dovetails for front
                up(wt/2)
                fwd(bd.y/2 + wt/2)
                    attach(RIGHT)
                    tags("mask")
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
                    fwd($parent_size.z/2 - wt)
                        screw_rail_grill(w=$parent_size.y - 2*screw_head_w,
                                         l=$parent_size.z/4 - wt,
                                         h=2*wt, $tags="mask");

                    back($parent_size.z/2 - wt)
                        right($parent_size.y/4 - wt/2)
                        screw_rail_grill(w=($parent_size.y - 2*screw_head_w)/2,
                                         l=$parent_size.z/4 - wt,
                                         h=2*wt, $tags="mask", anchor=TOP+RIGHT);
                }

                // Dovetails for top
                attach(TOP) edge_dovetail("male", bd.y);

                // Dovetails for front
                up(wt/2)
                    fwd(bd.y/2 + wt/2)
                    attach(LEFT)
                    tags("mask")
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

module main_part(anchor=CENTER, orient=TOP, spin=0) {
    size = bd + wt*[2,2,2];
    attachable(size=size, anchor=anchor, orient=orient, spin=spin) {
        show("main") make_part();
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
    explode_out(LEFT)
        show("left-c") make_part();
    explode_out(RIGHT)
        show("right-c") make_part();
    color(palette[1]) show("main") make_part();

    explode_out(FORWARD)
        color(palette[3], alpha=0.8) show("top") make_part();

    explode_out(UP)
         color(palette[4], alpha=0.5) show("front") make_part();



 } else if (Piece == "Main with connectors") {
    show("main connector") make_part();
 } else if (Piece == "Front") {
    // Front is really thin so needs less inset
    add_base(0.3, 0.75, 0.1, enable=Add_base)
        make_front(anchor=TOP, orient=BOTTOM);
 } else if (Piece == "Top") {
    // Top piece can't be printed directly on the platform or it warps during
    // curing
    make_top(anchor=TOP, orient=BOTTOM);
 } else {
    add_base(0.3, 1.5, 0.1, enable=Add_base)
        if (Piece == "Main") {
            main_part(anchor=BOTTOM);
        } else if (Piece == "Side connector") {
            pp15_casing(jack=false, anchor=BOTTOM);
        }
 }

$export_suffix = Piece;
