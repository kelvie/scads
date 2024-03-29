include <lib/BOSL2/std.scad>
include <lib/add-base.scad>
include <lib/fasteners.scad>
include <lib/text.scad>
// a case for the https://www.adafruit.com/product/4090
// to make it easier to plug in and out

Add_base = false;
Part = "All"; // [All]


Board_height=13.97;
Slop = 0.15;
Min_wall_thickness = 1;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

Board_width = 20.32;

USB_cutout_width = 8.94;
USB_port_height = 3.4;
USB_port_depth = 8;
Hole_spacing = 15.24;
Hole_yoffset_from_top = 2.54;
Pin_header_cutout = [5.09, 4.03, 0];
Resistor_cutout = [3.9, 3.5, 0.5];
Resistor_cutout_yoffset_from_bottom = 4.876;

module tapered_cuboid(size, slop=0.3, anchor, orient, spin, flip=false) {
  attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
    prismoid(size1=[size.x, size.y] + slop*[1, 1], size2=[size.x, size.y],
              h=size.z, anchor=CENTER) {
      // Add a taper at the top for more easy printing as well
      size2 = flip ? [size.x, 0] : [0, size.y];
      position(TOP)
        prismoid(size1=[size.x, size.y], size2=size2, h=slop);
    }

    children();
  }

}
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
          m2dot5_hole(h=size.z*2);
        }

        // Cutout for the USB port
        tags("cutme") position(BOTTOM+BACK) back($eps) down($eps)
          tapered_cuboid([USB_cutout_width, USB_port_depth, USB_port_height],
          anchor=BOTTOM+BACK);

        tags("cutme") position(FRONT+RIGHT) fwd($eps) right($eps)
          cuboid([Pin_header_cutout.x, Pin_header_cutout.y, size.z + 2*$eps], anchor=FRONT+RIGHT);

        tags("cutme") position(BOTTOM+LEFT+FRONT) down($eps) left($eps) back(Resistor_cutout_yoffset_from_bottom)
          tapered_cuboid(Resistor_cutout, anchor=BOTTOM+LEFT+FRONT, flip=true);

        margin=0.5;
        tags("cutme") position(TOP) up($eps) {
          label("5 VDC", anchor=TOP);
        }
        tags("cutme") position(TOP+RIGHT) up($eps) {
          left(margin) label("-", h=1, anchor=TOP, halign="right");
          right(margin) left(Pin_header_cutout.x) label("+", h=1, anchor=TOP, halign="left");
        }
      }
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

anchor = Add_base ? BOTTOM : CENTER;

add_base(enable=Add_base)
if (Part == "All") {
    part(orient=TOP, anchor=anchor);
}


$export_suffix = str(Part, "-take4");
