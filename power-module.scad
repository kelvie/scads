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
include <lib/add-base.scad>
include <lib/supports.scad>
include <lib/text.scad>

/* [View options] */
// Which piece to render.
Piece = "All"; // [All, Bottom with connectors, Bottom, Front, Top, Left connector, Right connector]

// Separate all the parts when viewing All pieces
Explode_parts = true;
Explode_offset = 20; // [0:1:100]

/* [Print Options] */
// Adds a extra base on the bottom to prevent elephant's foot
Add_base = true;

// Extra height for z-compression compensation
Extra_height = 0.3;

/* [Measurements] */
// Inner dimensions of the enclosure

Predefined_size = "55mm"; // [Custom, 25mm: 25mm wide, 55mm: 55mm wide]

// Only applicable when predefined size is Custom. Keep Y and Z the same if you want them to connect nicely...
Custom_width = 55;

Wall_thickness = 2;

// Multiplier of the grill width to space out by
Side_grill_spacing = 1.1;
Bottom_grill_spacing = 1.4;

// Grill rail angle
Rail_angle = 75; // [0:15:90]

// General slop for fits
Slop = 0.1;

// Inner width slop for fitting in PCB holders
Inner_width_slop = 0.4;

// Fit of the dovetails that hold the panels together -- increase to make looser
Dovetail_slop = 0.1; // [0:0.025:0.2]


/* [Front Connector options] */
Opening_type = "Anderson PP"; // [USB-C+A, Anderson PP]

/*  [Labels] */
Left_connector_label = "24V";
Right_connector_label = "24V";

/* [Fastener options] */
Screw_size = 3;
Screw_hole_diameter = 3.2;

// Assumes a countersunk screw
Screw_head_height = 1.65;

Nut_thickness = 2.4;
Nut_width = 5.5;


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

/* [Front Anderson PP options] */
// Only applicable when the front connector type is Anderson PP
Number_of_front_PP_connectors = 3;
// Left to right, needs to be same size as the number of connectors
Front_labels = ["5.0V", "14.0V", "19.5V"];
Front_label_text_size = 3;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

$eps = $fs/10;

chamf=Wall_thickness/3;
rounding=Wall_thickness/2;

// https://coolors.co/
palette = ["#e6efe9","#c5f4e0","#c2eaba","#a7c4a0","#8f8389"];

pds = Predefined_size;


common_yz = [0, 80, 45];

// Get the box dimensions
function get_box_dimensions() =
    common_yz + [1, 0, 0] * (
        pds == "Custom" ? Custom_width :
        pds == "25mm" ? 25 :
        pds == "55mm" ? 55 :
        0);

bd = get_box_dimensions() + Inner_width_slop * [1,0,0];
wt = Wall_thickness;

extra_height = Add_base ? Extra_height : 0;

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
            usb_c_jack_hole(l=2*wt,
                            tolerance=USB_C_hole_tolerance);

            // TODO: make a library for USB-A port
            usb_port_size = [13.2, 6];
            down(bd.z/2 - Bottom_USB_A_port_offset)
                cuboid([usb_port_size.x,
                        bd.y,
                        usb_port_size.y] + USB_C_hole_tolerance * [1, 0, 1] ,
                       rounding=0.25);
        }
    }
}

module bottom_wall(size) {

    diff("mask")
        cuboid([size.x, size.y, 0] + (wt+(extra_height))*[0, 0, 1],
               anchor=BOTTOM, rounding=rounding,
               edges=edges("ALL", except=[TOP])) {


        if (Opening_type == "Modular") {
            // TODO: finish this, there aren't modular ones yet
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
    m3_screw_rail_grill(l=$parent_size.z-2*wt,
                        w=d,
                        h=wt*2,
                        angle=Rail_angle,
                        spacing_mult=Side_grill_spacing);
}

module right_wall(size, inner_size) {
    diff("mask")
        cuboid([wt, size.y, size.z],
               anchor=RIGHT+TOP,
               rounding=rounding,
               edges=edges("ALL", except=[TOP, LEFT])) {

        if (Opening_type == "Modular") {
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
                    usb_c_jack_hole(l=2*wt,
                                    tolerance=USB_C_hole_tolerance);

                // TODO: make a library for USB-A port
                usb_port_size = [13.2, 6];
                down($parent_size.z/2 - Bottom_USB_A_port_offset)
                    cuboid([usb_port_size.x,
                            bd.y,
                            usb_port_size.y] + USB_C_hole_tolerance * [1, 0, 1] ,
                           rounding=0.25);
            }
            children();
        }
    } else if (Opening_type == "Anderson PP") {
        size = [inner_size.x, wt, height];
        psz = pp15_get_inside_size();

        attachable(size=size, orient=orient, anchor=anchor, spin=spin) {
            w=get_box_dimensions().x;

            diff("diffme")
                cuboid(size) tags("diffme") {

                if (orient == BOTTOM) {
                    // Top piece, cut out windows for anderson connectors
                    position(TOP)
                        down(extra_height)
                        pp15_multi_holder_cutout(t=wt,
                                                 n=Number_of_front_PP_connectors,
                                                 width=w,
                                                 orient=TOP,
                                                 anchor=TOP);
                } else if (orient == TOP) {
                    n = len(Front_labels);
                    // Add labels
                    spacing = w / (n + 1);
                    up($parent_size.z/4) position(LEFT+FRONT) for (i=[1:n]) {
                        fwd($eps) right(i*spacing) label(text=Front_labels[i-1],
                                                         orient=FRONT,
                                                         anchor=TOP,
                                                         h=Front_label_text_size,
                                                         font="Noto Sans:style=Bold");
                    }

                }
            }
            children();
        }
    }
}

module bottom_grill() {
    module _grill(w, l, angle) {
        back(l/2)
            m3_screw_rail_grill(l=l, w=w, h=wt*2,
                                angle=angle,
                                spacing_mult=Bottom_grill_spacing,
                                maxlen=30, outset=1.25, extra_height=extra_height);
    }
    edge_size = 2*m3_screw_head_height_countersunk();

    // Grill for screws
    attach(BOTTOM, $overlap=-$eps)
        tags("mask") {
        back(wt)
            _grill(angle=90,
                   w=$parent_size.x - edge_size,
                   l=$parent_size.y/2 - edge_size
                   );

        mirror(BACK)
            _grill(angle=0,
                   w=$parent_size.x - edge_size,
                   l=$parent_size.y/2 - edge_size);
    }

}

// nearterm TODO:
// - round the USB openings

// Size of dovetails that fit the bottom to the top piece
back_dovetail_ratio = 0.15;
front_dovetail_ratio = 0.15;

module make_bottom(anchor=BOTTOM, orient=TOP, spin=0) {
    inner_size = [bd.x, bd.y, bd.z/2];
    size = inner_size + wt*[2,2,1] + extra_height*[0,0,1];

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
                cuboid([size.x, wt+$eps, wt+$eps], anchor=BACK+TOP, $tags="mask") {
                position(FRONT+BOTTOM)
                    hull() move_copies([[0,0,0], Slop*FRONT])
                    xrot(45)
                        cuboid(size=[$parent_size.x, $parent_size.y, 2/sqrt(2)*$parent_size.z], anchor=BOTTOM+FRONT);
            }

            // Add a notch to fit the other part in the front
            position(FRONT+TOP)
                    cuboid([wt, wt, wt],
                           rounding=rounding,
                           edges=edges(RIGHT+FRONT),
                           anchor=FRONT+BOTTOM) {
                position(BACK+TOP) {
                            back_half(s=2*$parent_size.y) xrot(45)
                                cuboid(size=[$parent_size.x, $parent_size.y, sqrt(2)*$parent_size.z],
                                       anchor=BACK+TOP);
                        }
                    }

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
            // left wall
            mirror(LEFT)
                position(RIGHT+TOP)
                _right_wall() {
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

            // right wall
            position(RIGHT+TOP)
            _right_wall() {
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
                       rounding=rounding,
                       edges=edges("ALL", except=[TOP, FRONT])) {
                // when printed with the opening straithgt up, square nuts seem
                // to require less slop
                sqnut_slop = 0.75 * Slop;

                // Make sure there is at least 40mm between screw holes
                n = ceil($parent_size.x/40);
                xcopies(n=n, l=$parent_size.x * (1 - 1/n))
                    position(TOP+FRONT)
                    m3_sqnut_holder(wall=wt/2,
                                    chamfer=chamf/2,
                                    edges=edges("ALL", except=[BACK, BOTTOM]),
                                    orient=TOP,
                                    anchor=BACK+BOTTOM, slop=sqnut_slop) {
                    sh_sz = m3_sqnut_holder_size(wall=wt/2, slop=sqnut_slop);
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
        difference() {
            grill_length = size.y/2 - 2*wt + abs(pp15_get_center_yoffset());

            _part();
            down(wt/2) {
            attach(RIGHT, $overlap=-$eps)
                right(grill_length / 2 - abs(pp15_get_center_yoffset()) + wt)
                side_wall_grill(d=grill_length, $tags="mask");

            attach(LEFT, $overlap=-$eps)
                right(grill_length / 2 - abs(pp15_get_center_yoffset()) + wt)
                side_wall_grill(d=grill_length, $tags="mask");
            }

            bottom_grill();
        }
        children();
    }
}

module make_top(anchor=CENTER, orient=TOP, spin=0) {
    inner_size = [bd.x, bd.y, bd.z/2];
    size = inner_size + wt*[2,2,1] + extra_height*[0,0,1];

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
                           anchor=FRONT+TOP, $tags="mask") {
                    position(BACK+BOTTOM)
                        hull() move_copies([CENTER, Slop*BACK])
                        xrot(-45)
                        cuboid(size=[$parent_size.x, $parent_size.y, 2/sqrt(2)*$parent_size.z], anchor=BOTTOM+BACK);
                }
            }

            // Back wall
            diff("mask")
                position(BACK+BOTTOM)
                cuboid([size.x, 0, size.z] + wt * [0, 1, 1],
                       anchor=BACK+BOTTOM,
                       rounding=rounding,
                       edges=edges("ALL", except=[TOP, FRONT])) {
                // Make sure there is at least 40mm between screw holes
                n = ceil($parent_size.x/40);
                xcopies(n=n, l=$parent_size.x * (1 - 1/n))
                    down(2*wt - 2*Slop)
                    position(TOP+BACK)
                    back($eps)
                    m3_screw_rail(l=0, h=2*wt, orient=BACK, $tags="mask");

                // Add an angled block before the back notch; if this area wre
                // on the other side (with the dovetail cutout), it breaks easily.
                mirror_copy(RIGHT) position(FRONT+TOP+LEFT) {
                    front_half(s=100) xrot(-45)
                        cuboid(size=[wt, $parent_size.y, sqrt(2)*wt],
                               anchor=FRONT+TOP+LEFT);
                }
            }

            // Optional front plate
            position(FRONT)
                front_wall(size, inner_size, height=size.z-2*wt, anchor=FRONT, orient=BOTTOM);
        }
    }

    attachable(size=size, anchor=anchor, orient=orient, spin=spin) {
        difference() {
            _part();
            down(wt/2)
            mirror_copy(LEFT) attach(RIGHT, $overlap=-$eps)
                side_wall_grill(d=size.y - 2*wt,
                                $tags="mask");
            bottom_grill();
        }

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


$export_suffix = str(Opening_type, "-", Piece, "-", get_box_dimensions().x, "mm");

// Optionally show the pieces exploded for "All"
if (Piece == "All") {
    color(palette[1], alpha=1) make_bottom(anchor=TOP);

    explode_out(RIGHT)
    right(bd.x/2 + wt)
        pp15_casing(anchor=TOP+RIGHT, orient=LEFT, text=Right_connector_label);

    explode_out(LEFT)
    zrot(180) right(bd.x/2 + wt)
        pp15_casing(anchor=TOP+RIGHT, orient=LEFT, text=Left_connector_label);

    explode_out(UP)
        color(palette[3], alpha=0.99) make_top(anchor=TOP, orient=BOTTOM);

    if (Opening_type == "USB-C+A" || Opening_type == "Anderson PP") {
    } else {
         explode_out(FORWARD)
             fwd(bd.y/2)
             color(palette[4], alpha=0.99) make_front(anchor=BACK);
    }

 } else if (Piece == "Bottom with connectors") {
    color(palette[1], alpha=1) make_bottom(anchor=TOP);

    right(bd.x/2 + wt)
        pp15_casing(anchor=TOP+RIGHT, orient=LEFT, text=Right_connector_label);

    zrot(180) right(bd.x/2 + wt)
        pp15_casing(anchor=TOP+RIGHT, orient=LEFT, text=Left_connector_label);

 } else if (Piece == "Front") {
    // Front is really thin so needs less inset
    add_base(0.3, 0.75, 0.1, enable=Add_base)
        make_front(anchor=TOP, orient=BOTTOM);
 } else if (Piece == "Top") {
    add_base(Extra_height, 1.5, Extra_height, enable=Add_base) {
        make_top(anchor=BOTTOM, orient=TOP);
        rect([bd.x, bd.y], center=true);
    }
 } else if (Piece == "Bottom") {
    add_base(Extra_height, 1.5, Extra_height, enable=Add_base) {
        make_bottom(anchor=BOTTOM);
        rect([bd.x, bd.y], center=true);
    }
 } else {
    add_base(0.3, 1, 0.1, enable=Add_base)
        if (Piece == "Right connector") {
            pp15_casing(jack=false, anchor=BOTTOM, text=Right_connector_label);
        } else if (Piece == "Left connector") {
            pp15_casing(jack=false, anchor=BOTTOM, text=Left_connector_label);
        }
    $export_suffix = str(Opening_type, "-", Piece);
 }


