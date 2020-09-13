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
include <lib/supports.scad>

/* [View options] */
// Which piece to render.
Piece = "All"; // [All, Bottom with connectors, Bottom, Front, Top, Left connector, Right connector]

// Separate all the parts when viewing All pieces
Explode_parts = true;
Explode_offset = 20; // [0:1:100]

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
Side_grill_spacing = 1.1;
Bottom_grill_spacing = 1.5;

// Grill rail angle
Rail_angle = 60; // [0:15:90]

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

module bottom_wall(size) {
    module _grill(w, angle) {
        l = $parent_size.y/2 - wt;
        back(l/2)
            m3_screw_rail_grill(l=l, w=w, h=wt*2,
                                angle=angle,
                                spacing_mult=Bottom_grill_spacing);
    }

    diff("mask")
        cuboid([size.x, size.y, 0] + wt*[0, 0,1],
               anchor=BOTTOM, chamfer=chamf,
               edges=edges("ALL", except=[TOP])) {

        // Split up the long rail when it's past 30mm
        grill_w = $parent_size.x;
        grill_w_n = ceil(grill_w / 30);
        // Grill for screws
        attach(BOTTOM, $overlap=-$eps)
            tags("mask") {
            _grill(angle=90, w=grill_w - 2*wt);

            // Split up the long rails
            mirror(BACK)
                for (i = [0:grill_w_n-1])
                    left((i - (grill_w_n - 1)/2)*(grill_w - 2*wt)/grill_w_n)
                        _grill(angle=0, w=grill_w/grill_w_n - 2*wt);
        }

        if (Opening_type == "USB-C+A") {
        } else {
            // Slot for front plate
            position(FRONT+TOP)
                up($eps)
                back(wt/2)
                cuboid([$parent_size.x / 2, wt/2, wt/2] + Slop * [2, 1, 1],
                       anchor=TOP+FRONT,
                       chamfer=-chamf/2, edges=TOP,
                       $tags="mask");
        }

        children();
    }
}


module side_wall_grill(d) {
        m3_screw_rail_grill(l=$parent_size.z - 2*wt,
                            w=d,
                            h=wt*2,
                            angle=Rail_angle,
                            spacing_mult=Side_grill_spacing);
}

module right_wall(size, inner_size) {
    diff("mask")
        cuboid([wt, size.y, size.z],
               anchor=RIGHT+TOP,
               chamfer=chamf,
               edges=edges("ALL", except=[TOP, LEFT])) {

        if (Opening_type == "USB-C+A") {
        } else {
            // Dovetails for front
            up(wt/2 - inner_size.z/4)
                fwd(bd.y/2 + wt/2)
                attach(LEFT)
                edge_dovetail("male", inner_size.z/2);
        }

        children();
    }
}

module front_wall(size, inner_size, height,
                  anchor=CENTER, orient=TOP, spin=0) {
    if (Opening_type == "USB-C+A") {
        size = [inner_size.x, wt, height];
        attachable(size=size, orient=orient, anchor=anchor, spin=spin) {
            diff("diffme")
                cuboid(size) tags("diffme") {

                // USB-C hole
                down($parent_size.z/ 2 - Bottom_USB_C_port_offset)
                    usb_c_jack_hole(l=Box_dimensions.y,
                                    tolerance=USB_C_hole_tolerance);

                // TODO: make a library for USB-A port
                usb_port_size = [13.2, 6];
                down($parent_size.z/2 - Bottom_USB_A_port_offset)
                    cuboid([usb_port_size.x,
                            Box_dimensions.y,
                            usb_port_size.y] + USB_C_hole_tolerance * [1, 0, 1] ,
                           rounding=0.25);
            }
            children();
        }
    }
}

// future TODOs
// TODO: removeable inner plate to swap in and out... this way I can swap this
//       between the buck convertor and this
// TODO: text on side connectors to know which one's which, and what voltages
// TODO: customize front plate
// TODO: front anderson powerpole holder
// TODO: build in PCB holder (maybe something like a sandwich press for the top)

// Size of dovetails that fit the bottom to the top piece
back_dovetail_ratio = 1/8;
front_dovetail_ratio = 1/8;

module make_bottom(anchor=BOTTOM, orient=TOP, spin=0) {
    inner_size = [bd.x, bd.y, bd.z/2];
    size = inner_size + wt*[2,2,1];

    module _right_wall() {
        right_wall(size, inner_size) {
            dovetail_base_l = inner_size.y;

            // Dovetails on top (back)
            back(dovetail_base_l * (1 - back_dovetail_ratio)/2)
                attach(TOP)
                edge_dovetail("female", back_dovetail_ratio * dovetail_base_l, spin=180);

            // Dovetails on top (front)
            fwd(dovetail_base_l * (1 - front_dovetail_ratio)/2)
                attach(TOP)
                edge_dovetail("male", front_dovetail_ratio*dovetail_base_l);

            // Slot to go into a rail on the walls of the other part
            position(TOP)
                down($eps)
                cuboid([wt/3 - Slop, 2* abs(pp15_get_center_yoffset()), wt/2 - Slop],
                       chamfer=chamf/3, edges=TOP,
                       anchor=BOTTOM
                       );

            // Cut out notch to fit the other part in the back
            position(BACK+TOP)
                back($eps)
                up($eps)
                cuboid([size.x, wt+$eps, wt+$eps], anchor=BACK+TOP, $tags="mask");

            // Add a notch to fit the other part in the front
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
                bottom_wall(size);


            // left/right walls
            mirror(LEFT)
                position(RIGHT+TOP)
                _right_wall() {
                attach(RIGHT, $overlap=-$eps)
                    left(($parent_size.y/2 - wt) / 2)
                    side_wall_grill(d=$parent_size.y/2 - 2*wt, $tags="mask");

                mirror(FRONT) position(TOP+RIGHT) {
                    pp15_base_plate(anchor=TOP+RIGHT, orient=LEFT);
                    tags("mask")
                        right($eps) {
                        pp15_casing(anchor=TOP+RIGHT,
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

            position(RIGHT+TOP)
            _right_wall() {
                attach(RIGHT, $overlap=-$eps)
                    right(($parent_size.y/2 - wt) / 2)
                    side_wall_grill(d=$parent_size.y/2 - 2*wt, $tags="mask");

                position(TOP+RIGHT) {
                    pp15_base_plate(anchor=TOP+RIGHT, orient=LEFT);
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
                       edges=edges("ALL", except=[TOP, FRONT])) {
                position(TOP+FRONT)
                    m3_sqnut_holder(wall=wt/2,
                                    chamfer=chamf/2,
                                    edges=edges("ALL", except=[BACK, BOTTOM]),
                                    orient=TOP,
                                    anchor=BACK+BOTTOM) {
                    sh_sz = m3_sqnut_holder_size(wall=wt/2);
                    up($eps)
                    position(BOTTOM)
                        mirror(BACK) bottom_support([sh_sz.x, sh_sz.y],
                                                    chamfer=chamf/2);
                }
            }

            // Optional front plate
            position(FRONT+BOTTOM)
                up(wt)
                front_wall(size, inner_size, height=size.z, anchor=FRONT+BOTTOM);
        }
    }

    attachable(size=size, anchor=anchor, orient=orient, spin=spin) {
        _part();
        children();
    }
}

module make_top(anchor=CENTER, orient=TOP, spin=0) {
    inner_size = [bd.x, bd.y, bd.z/2];
    size = inner_size + wt*[2,2,1];

    module _part() {
        // Debug
        // % cuboid(size);
        hide("hidden")
            cuboid(size, $tags="hidden")
            tags("nothidden") {
            position(BOTTOM)
                bottom_wall(size);


            // left/right walls
            mirror_copy(LEFT)
                position(RIGHT+TOP)
                right_wall(size, inner_size) {
                attach(RIGHT, $overlap=-$eps)
                    side_wall_grill(d=$parent_size.y - 2*wt,
                                    $tags="mask");

                dovetail_base_l = inner_size.y;

                // Dovetail on top (back)
                back(dovetail_base_l * (1 - back_dovetail_ratio)/2)
                    attach(TOP)
                    edge_dovetail("male", back_dovetail_ratio * dovetail_base_l, spin=180);

                // Dovetail on top (front)
                fwd(dovetail_base_l * (1 - front_dovetail_ratio)/2)
                attach(TOP)
                    edge_dovetail("female", front_dovetail_ratio*dovetail_base_l);

                // Regular rail for top part's slot to go into
                position(TOP)
                    up($eps)
                    cuboid([wt/3 + Slop, dovetail_base_l/2, wt/2 + Slop],
                    chamfer=-chamf/3, edges=TOP,
                    anchor=TOP,
                    $tags="mask");

                // Cut out a notch on the top+front to fit the top part
                position(FRONT+TOP)
                    up($eps)
                    fwd($eps)
                    cuboid((wt+$eps) * [1, 1, 1],
                           anchor=FRONT+TOP, $tags="mask");
            }

            // Back wall
            diff("mask")
                position(BACK+BOTTOM)
                cuboid([size.x, 0, size.z] + wt * [0, 1, 1],
                       anchor=BACK+BOTTOM,
                       chamfer=chamf,
                       edges=edges("ALL", except=[TOP, FRONT])) {
                down(2*wt - 2*Slop)
                    position(TOP+BACK)
                    back($eps)
                    m3_screw_rail(l=0, h=2*wt, orient=BACK, $tags="mask");
            }

            // Optional front plate
            position(FRONT)
                front_wall(size, inner_size, height=size.z-2*wt, anchor=FRONT, orient=BOTTOM);
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
    color(palette[1], alpha=1) make_bottom(anchor=TOP);

    explode_out(RIGHT)
    right(bd.x/2 + wt)
        pp15_casing(anchor=TOP+RIGHT, orient=LEFT);

    explode_out(LEFT)
    zrot(180) right(bd.x/2 + wt)
        pp15_casing(anchor=TOP+RIGHT, orient=LEFT);

    explode_out(UP)
        color(palette[3], alpha=0.99) make_top(anchor=TOP, orient=BOTTOM);

    if (Opening_type == "USB-C+A") {
    } else {
         explode_out(FORWARD)
             fwd(bd.y/2)
             color(palette[4], alpha=0.99) make_front(anchor=BACK);
    }

 } else if (Piece == "Bottom with connectors") {
    color(palette[1], alpha=1) make_bottom(anchor=TOP);

    right(bd.x/2 + wt)
        pp15_casing(anchor=TOP+RIGHT, orient=LEFT);

    zrot(180) right(bd.x/2 + wt)
        pp15_casing(anchor=TOP+RIGHT, orient=LEFT);


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

$export_suffix = str(Opening_type, "-", Piece);
