include <BOSL2/std.scad>

Default_tolerance=0.3;
usb_c_hole_w = 9;
usb_c_hole_h= 3.3;

// This is a guess
usb_c_hole_r = usb_c_hole_h / 3;

// TODO:
// - chamfer or round the opening...
// - Make attachable

// Creates a usb c hole of length l (in the y direction)
// centered about origin. Use with difference()
module usb_c_jack_hole(l=20, tolerance=Default_tolerance) {
    back(l/2) xrot(90) linear_extrude(l)
        rect(size=[usb_c_hole_w, usb_c_hole_h] + tolerance*[1,1],
             rounding=usb_c_hole_r, center=true, $tags=$tags);
}
