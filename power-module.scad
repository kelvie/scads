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
Explode_offset = 15; // [0:1:60]

/* [Print Options] */
// Adds a extra base on the bottom to prevent elephant's foot
Add_base = true;

/* [Measurements] */
// Inner dimensions of the enclosure

Predefined_size = "25mm"; // [Custom, 25mm: 25mm wide, 55mm: 55mm wide]

// Only applicable when predefined size is Custom. Keep Y and Z the same if you want them to connect nicely...
Box_dimensions = [50, 70, 40];

Wall_thickness = 2;

// General slop for fits
Slop = 0.1;

// Fit of the dovetails that hold the panels together -- increase to make looser
Dovetail_slop = 0.075; // [0:0.025:0.2]
/* [Front Connector options] */
Opening_type = "USB-C"; // [USB-C, Anderson PP]

/* [Fastener options] */

Screw_hole_diameter = 3.2;

// Assumes a countersunk screw
Screw_head_height = 1.65;

Nut_thickness = 2.4;
Nut_width = 5.5;

/* [Wire hook options] */
Use_wire_hooks = true;
Wire_thickness = 2.3;

/* [USB-C options] */
// From the bottom inside wall
Bottom_USB_C_port_offset = 9;
USB_C_hole_tolerance = 1;

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

bd = get_box_dimensions() + Slop * [2, 0, 0];
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
screw_head_w = hole_d + 2*screw_head_h;

module screw_rail(l, h, anchor=CENTER, orient=TOP, spin=0) {
    big_d = screw_head_w;
    size = [l + big_d, big_d, h];

    module _cutout() {
        hull()
            mirror_copy(LEFT)
            left(l/2)
            cyl(d=hole_d, h=h);

        hull()
            mirror_copy(LEFT)
            left(l/2)
            up(h/2)
            cyl(d2=big_d,
                d1=hole_d,
                h=screw_head_h,
                anchor=TOP);
    }

    attachable(size=size, anchor=anchor, orient=orient, spin=spin) {
        _cutout();
        children();
    }
}

// TODO: this is ugly af
module screw_rail_grill(w, l, h) {
    xcopies(l=w, spacing=1.5*screw_head_w)
        screw_rail(l=l , h=h, anchor=TOP+LEFT, spin=90);
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
    diff("diffme")
        cuboid([bd.x, 0, bd.z] + wt*[0, 1, 0],
               anchor=anchor, orient=orient,
               edges=edges("ALL", except=BACK,BOTTOM)) {

        // Dovetails on both sides
        mirror_copy(LEFT) attach(LEFT)
            edge_dovetail("male", bd.z);

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

        tags("diffme")
            down(bd.z/ 2 - Bottom_USB_C_port_offset)
            usb_c_jack_hole(l=Box_dimensions.y,
                            tolerance=USB_C_hole_tolerance);
    }

}

// future TODOs
// TODO: removeable inner plate to swap in and out... this way I can swap this
//       between the buck convertor and this (needs bottom holes?)
// TODO: stack 2-up? (need to think about adjustability, or have them easy to
//       slide out)
// TODO: text on side connectors to know which one's which, and what voltages
// TODO: customize front plate
// TODO: split parts into modules rather than use tags...
// TODO: webbings to hold up nut holder, and other places?
// TODO: front anderson powerpole holder

// need TODOs
// TODO: refactor to be able to rotate pieces + use addbase
// TODO: final printability check
module make_part() {

    // Whether or not to cover all the connectors... I don't think this is
    // helpful as it hides the colours.
    connector_jack = false;
    connector_spin = 0;

    module make_wire_hook(width, num_wires=4) {
        if (Use_wire_hooks)
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
                left($eps)
                    down($parent_size.z/2 - wt)
                    attach(LEFT)
                    screw_rail_grill(
                        w=$parent_size.y - 2*screw_head_w,
                        l=$parent_size.z/4 - wt,
                        h=2*wt, $tags="mask");

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
                right($eps)
                    down($parent_size.z/2 - wt)
                    attach(RIGHT)
                    screw_rail_grill(
                        w=$parent_size.y - 2*screw_head_w,
                        l=$parent_size.z/4 - wt,
                        h=2*wt, $tags="mask");


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
                    make_wire_hook($parent_size.y / 4);
            }

            position(BACK)
                cuboid([bd.x, 0, bd.z] + wt*[2,1,2],
                       anchor=FRONT,
                       chamfer=chamf,
                       edges=edges("ALL", except=[FRONT])) {
                up($parent_size.z/2 - wt - Slop)
                    attach(FRONT)
                    make_wire_hook($parent_size.x / 2, 2);
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
    explode_out(FORWARD)
        color(palette[4]) show("front") make_part();
    explode_out(UP)
        color(palette[3]) show("top") make_part();
    explode_out(LEFT)
        show("left-c") make_part();
    explode_out(RIGHT)
        show("right-c") make_part();
    color(palette[1]) show("main") make_part();

 } else if (Piece == "Main with connectors") {
    show("main connector") make_part();
 } else if (Piece == "Front") {
    // Front is really thin so needs less inset
    add_base(0.3, 0.75, 0.1, enable=Add_base)
        make_front(anchor=TOP, orient=BOTTOM);
 } else {
    add_base(0.3, 1, 0.1, enable=Add_base)
        if (Piece == "Main") {
            main_part(anchor=BOTTOM);
        } else if (Piece == "Side connector") {
            pp15_casing(jack=false, anchor=BOTTOM);
        } else if (Piece == "Top") {
            make_top(anchor=TOP, orient=BOTTOM);
        }
 }

$export_suffix = Piece;
