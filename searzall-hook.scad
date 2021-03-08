include <lib/BOSL2/std.scad>
include <lib/add-base.scad>


Small_diameter = 16.1;
Large_diameter = 25.8;
Thickness = 8;
Clearance = 2;
Small_clearance = 0.5;
Hook_height = 40;
Hole_size = 3.4;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;


outer_sz = Large_diameter*[1, 1, 0] + Thickness*[1, 1, 2];
// Make a hook that can hook onto the grill? or maybe something more permanent
// on the searzall itself, hmmm.
module holder(anchor=CENTER, spin=0, orient=TOP) {
    size = outer_sz;

    module _part() {
        difference() {
            cuboid(size) {
                position(BOTTOM)
                    left(size.x/2)
                    cuboid([2*size.x, size.y, size.z*3], anchor=TOP);
                position(LEFT)
                    cuboid([size.x, size.y, size.z], anchor=RIGHT);
            }
            hull()
                move_copies([[0,0,0], [-2*Large_diameter, 0, 0]])
                cyl(d=Large_diameter+Clearance, h=Thickness, anchor=BOTTOM,
                    $fa=1);
        }
    }
    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

add_base()
up(Thickness) yrot(-90) difference() {
    union() {
        cuboid([Thickness, outer_sz.y, Hook_height],
               anchor=RIGHT+BOTTOM,
               rounding=4,
               edges=edges("ALL", except=BOTTOM));
        intersection() {
            yrot(45) holder(anchor=LEFT+BOTTOM);
            up(30) left(Thickness) cuboid([100, outer_sz.y, 60],
                   anchor=LEFT+TOP, rounding=4);
        }
    }
    up(20)
        cuboid([5*Large_diameter,
                Small_diameter + Clearance,
                10*Thickness],
               anchor=TOP,
               rounding=Small_diameter/2);

    // Screw holes...
    yflip_copy() up(Hook_height)
    down(10)
        fwd(10)
        xcyl(d=Hole_size, h=20);
}
