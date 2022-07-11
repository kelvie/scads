include <lib/BOSL2/std.scad>
include <lib/add-base.scad>
include <lib/fasteners.scad>
// a case for the https://www.adafruit.com/product/4090
// to make it easier to plug in and out

Add_base = false;
Part = "All"; // [All]


Board_height=13.97;
Slop = 0.15;
Min_wall_thickness = 2;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

Board_width = 20.32;

USB_cutout_width = 8.94;
USB_port_height = 3.4;
USB_port_depth = 8;
Hole_spacing = 15.24;
Hole_diameter = 2.5;
Hole_yoffset_from_top = 2.54;
Pin_header_cutout = [5.09, 4.03, 0];
Resistor_cutout = [3.9, 3.24, 0.5];
Resistor_cutout_yoffset_from_bottom = 4.876;

module part(anchor=CENTER, spin=0, orient=TOP) {
    size = [Board_width, Board_height, USB_port_height + Min_wall_thickness];

    module _part() {
      echo("overall size is: ", size);
      diff("cutme")
        // Screw holes, with space for a nut on top
        cuboid(size, rounding=Hole_yoffset_from_top, edges=edges("ALL", except=[TOP, BOTTOM])) {
        tags("cutme") mirror_copy(LEFT) left(Hole_spacing/2)
          fwd(Hole_yoffset_from_top)
          position(BACK) {
          position(TOP) up($eps) m2dot5_nut(h=2, anchor=TOP);
          cyl(d=Hole_diameter, h=size.z*2);
        }

        // Cutout for the USB port
        tags("cutme") position(BOTTOM+BACK) back($eps) down($eps)
          cuboid([USB_cutout_width, USB_port_depth, USB_port_height], anchor=BOTTOM+BACK);


        tags("cutme") position(FRONT+RIGHT) fwd($eps) right($eps)
          cuboid([Pin_header_cutout.x, Pin_header_cutout.y, size.z + 2*$eps], anchor=FRONT+RIGHT);

        tags("cutme") position(BOTTOM+LEFT+FRONT) down($eps) left($eps) back(Resistor_cutout_yoffset_from_bottom)
          cuboid(Resistor_cutout, anchor=BOTTOM+LEFT+FRONT);
      }
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

anchor = Add_base ? TOP : CENTER;

add_base(enable=Add_base)
if (Part == "All") {
    part(orient=BOTTOM, anchor=anchor);
}

$export_suffix = str(Part, "-take1");
