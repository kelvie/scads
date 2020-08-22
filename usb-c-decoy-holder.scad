// TODO: unfinished. couldn't figure out how to mount the board, there aren't
// any screw holes.

include <lib/BOSL2/std.scad>
// for usb_* constants
include <lib/usb-c.scad>


Slot_thickness = 1.8;
Slot_tolerance = 0.2;
Front_overhang = 2;
Front_outset = 1;
Cutout_size = [10, 5];
USB_hole_tolerance = 0.3;
Overall_board_height = 4.2;
Overall_board_length = 20;
PCB_thickness = 0.8;
Wall_thickness = 1;
Overall_board_width = 10;

/* [Hidden] */

$fa=$preview ? 10: 2;
$fs=0.025;

module pcbHolder() {
    cuboid([Overall_board_width, Overall_board_length, Wall_thickness],
           anchor=TOP+FRONT,
           chamfer=Wall_thickness / 4,
           edges=edges("ALL", except=FRONT));
}

difference() {
    union() {
        cuboid([Cutout_size.x, Slot_thickness, Cutout_size.y] + Slot_tolerance * [-1, 1, -1]) {
            attach(BACK, norot=true) {
                cuboid([Cutout_size.x, Front_outset, Cutout_size.y] + Front_overhang * [1, 0, 1],
                       anchor=FRONT)
                    attach(BACK, norot=true)
                    down(usb_c_hole_h / 2 + (Overall_board_height - usb_c_hole_h))
                    pcbHolder();

                }
            attach(FRONT, norot=true)
                cuboid([Cutout_size.x, Front_outset, Cutout_size.y] + Front_overhang * [1, 0, 1],
                       anchor=FRONT);

        };
    }
    usb_c_jack_hole(tolerance=USB_hole_tolerance);
}

