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


/* [View options] */
// Which piece to render.
Piece = 0; // [0: All, 1: Front, 2: Main, 3: Top, 4: Left connector, 5: Right connector, 6: Main with connectors]

// Separate all the parts when viewing All pieces
Explode_parts = true;
Explode_offset = 15; // [0:1:30]

/* [Measurements] */
// Inner dimensions of the enclosure

Predefined_size = "CTP2"; // [Custom, CTP2: USB-C step down module]

// Only applicable when predefined size is Custom. Keep Y and Z the same if you want them to connect nicely...
Box_dimensions = [50, 70, 40];

Wall_thickness = 2;

PCB_width = 18;
PCB_depth = 50;
PCB_thickness = 1;

/* [Front Connector options] */
Opening_type = 0; // [0:USB A+C combo, 1: Anderson PP]

/* [USB-C options] */

// Downward in Z direction
USB_C_port_offset = 4;


/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;


chamf=Wall_thickness/3;

// https://coolors.co/
palette = ["#e6efe9","#c5f4e0","#c2eaba","#a7c4a0","#8f8389"];

pds = Predefined_size;

// TODO: calculate based on pcb size + appropriate minimums
// Get the box dimensions
// `CTP2` is this module I found on aliexpress: https://www.aliexpress.com/item/4000089427329.htm
function get_box_dimensions() =
    pds == "Custom" ? Box_dimensions :
    pds == "CTP2" ? [18, 70, 40] :
    [];


// TODO: stack 2-up (need to think about adjustability, or have them easy to slide out)
// TODO: cut slots for PCB
// TODO: holder for PCBs to be able to resist pulling + pushing in plugs
// TODO: cut vents on the back and sides (perhaps move connectors up near the top)
// TODO: slot for bottom of front plate to prevent movement
// TODO: adjust usb port dimension
// TODO: nut holder for the front part
// TODO: text on side connectors to know which one's which
// TODO: think about printability
module make_part() {
    bd = get_box_dimensions();
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
                 $slop=0.1,
                 $tags=$tags
            );
    }

    // Whether or not to cover all the connectors... I don't think this is
    // helpful as it hides the colours.
    connector_jack = false;
    connector_spin = 0;

    hide("hidden")
        cuboid(size=bd,
               anchor=CENTER,
               $overlap=0, $tags="hidden") {

        // Can't colour this because it overrides all children's colouring...
        // recolor(palette[1])
            tags("main") {
            position(BOTTOM)
                cuboid([bd.x, bd.y, 0] + wt*[2,2,1],
                       anchor=TOP, chamfer=chamf,
                       edges=edges("ALL", except=[TOP]));

            // Left wall
            position(LEFT)
                down(wt/2)
                diff("mask", "main")
                cuboid([0, bd.y, bd.z] + wt*[1,2,1],
                       anchor=RIGHT,
                       chamfer=chamf,
                       edges=edges("ALL", except=[RIGHT, TOP])) {


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
                        left(0.01)
                        pp15_casing(jack=false,
                                    anchor=TOP+RIGHT,
                                    spin=180-connector_spin,
                                    orient=RIGHT,
                                    mask=3);
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
                        right(0.01)
                        pp15_casing(jack=connector_jack,
                                    anchor=TOP+RIGHT,
                                    orient=LEFT,
                                    spin=connector_spin,
                                    mask=3);

                }
            }

            position(BACK)
                cuboid([bd.x, 0, bd.z] + wt*[2,1,2],
                       anchor=FRONT,
                       chamfer=chamf,
                       edges=edges("ALL", except=[FRONT]));

        }

        tags("top") position(TOP)
            fwd(wt/2)
            diff("diffme")
            cuboid([bd.x, bd.y, 0] + wt*[2,1,1],
                   anchor=BOTTOM, chamfer=chamf,
                   edges=edges("ALL", except=[BACK, BOTTOM])) {
            attach(BOTTOM) {
                mirror_copy(LEFT) left(bd.x/2 + wt/2) back(wt/2) edge_dovetail("female", bd.y, $tags="diffme");
            }
        };

        tags("front") position(FRONT)
            difference() {
            cuboid([bd.x, 0, bd.z] + wt*[0, 1, 0],
                   anchor=BACK,
                   edges=edges("ALL", except=BACK,BOTTOM)) {
                mirror_copy(LEFT) attach(LEFT)
                    edge_dovetail("male", bd.z);
            };
            down(USB_C_port_offset) usb_c_jack_hole(l=Box_dimensions.y);
        }
    }
}

tags = Piece == 1 ? "front" :
    Piece == 2 ? "main" :
    Piece == 3 ? "top" :
    Piece == 4 ? "left-c" :
    Piece == 5 ? "right-c" :
    Piece == 6 ? "main connector" :
    "";

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
if (Piece == 0) {
    explode_out(FORWARD)
        color(palette[4]) show("front") make_part();
    explode_out(UP)
        color(palette[3]) show("top") make_part();
    explode_out(LEFT)
        show("left-c") make_part();
    explode_out(RIGHT)
        show("right-c") make_part();
    color(palette[1]) show("main") make_part();

} else
    show(tags) make_part();
