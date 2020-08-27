include <lib/BOSL2/hull.scad>
include <lib/BOSL2/std.scad>

PCB_size = [18.22, 49.2, 1.57];
Power_module_size = [25, 80, 40];

Wall_thickness = 2;

Clamp_wall_height = 5;
Clamp_depth = 30;
Clamp_wall_thickness = 2;
Grip_size = 0.15; // [0.025:0.025:0.4]

// Square nut side, or flat to flat for hex
Nut_width = 5.5;
Nut_thickness = 2.4;

// Total middle gap size; operating width of the clamp
Middle_gap = 3;


Screw_hole_diameter = 3.2;

// Extra tolerance for push-in nuts, etc
Slop = 0.1;

Show_power_module_dimensions = false;

/* [hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

width=25;

ps = PCB_size;
wall = Wall_thickness;
chamf = wall / 4;

// Use 1mm walls for these...
nut_wall_t = Nut_thickness + 2;

// TODO: make threaded rods for fine adjustments in X-rotation?
// TODO: clamp in the X direction to hold it in, using something threaded...
// TODO: how to center the clamp? (using one thread to clamp, and one to center (X-offset))
// TODO: cut out a rough texture on the inside of the clamp


module pcb_back_holder() {
    // This will hold up the PCB from the back side, but will need to be screwed
    // in with a M3 screw
    diff("cutme")
        cyl(d=5, h=3, orient=FRONT) {
        attach(BOTTOM) cyl(d=3.5, h=$parent_size.z);
        attach(BOTTOM) cyl(d=3.1, h=$parent_size.z+0.01, $tags="cutme");
        attach(TOP) back($parent_size.y/2) down(1)
            cuboid($parent_size, anchor=BOTTOM, $tags="cutme");
    };
}

if ($preview) {
    // Spacing in the power module
    if (Show_power_module_dimensions) %cuboid(Power_module_size);

    // PCB
    color("green", 0.2) cuboid(size=ps);
}

// Creates a grip mask
module grip_mask(size, anchor=CENTER, spin=0, orient=TOP) {
    segments = floor(size.x / (size.z * sqrt(2)));

    // debug
    // %cuboid(size, anchor=anchor, spin=spin, orient=orient);

    attachable(size=[size.x, size.y, size.z*sqrt(2)], anchor=anchor, spin=spin, orient=orient) {
        xcopies(spacing=size.z*sqrt(2), n=segments)
            yrot(45) cuboid([size.z, size.y, size.z]);
        children();
    }

}

slop = Slop;

module attach_nut_cutout() {
    position(BOTTOM) down(slop) cuboid([2.4, 5.5, 5.5] + slop * [1,1,1],
                                       chamfer=-chamf,
                                       edges=BOTTOM,
                                       $tags="cutme",
                                       anchor=BOTTOM);
}

clt = Clamp_wall_thickness;

// TODO: 2 rails on the walls to adjust Z and Y orientation?
// XY rails on both? then just clamp to keep it in place?

module mirror_copy_yflip(v) {
    children(0);
    mirror(v) mirror(FORWARD) children(0);
}


// TODO: print threaded rod?
// TODO: somehow secure threaded rod or screw head
// TODO: somehow be able to turn threaded rod
// TODO: reposition screw holes so they can be tapered to print on its side
module make_clamps() {
    // Clamp wall
    diff("cutme")
        mirror_copy_yflip(LEFT)
        left(ps.x / 2)
        cuboid([clt, Clamp_depth, Clamp_wall_height+wall],
               chamfer=chamf,
               edges=edges("ALL", except=BOTTOM+RIGHT),
               anchor=RIGHT) {

        // Make the clamp wall grippy
        up(wall/2)attach(RIGHT, $overlap=0)
            grip_mask([Clamp_wall_height, Clamp_depth, Grip_size],
                      spin=90, $tags="cutme");


        // This part holds the bottom of the PCB
        position(LEFT+BOTTOM)
            cuboid([(ps.x - nut_wall_t - Middle_gap)/2 + wall, Clamp_depth, wall],
                   chamfer=chamf,
                   anchor=LEFT+BOTTOM) {

            // This part attaches onto the middle wall between the clamp
            position(RIGHT+TOP)
                cuboid([nut_wall_t, Clamp_depth, Nut_width+wall],
                       chamfer=chamf,
                       anchor=TOP+RIGHT)
                tags("cutme") {

                // For the middle screw to center the clamp
                left(wall)
                    up(slop/2)
                    position(BOTTOM)
                    cyl(d=Nut_width-slop, h=nut_wall_t,
                        anchor=LEFT,
                        orient=LEFT
                        );

                // Nut holder for other side of clamp
                fwd(Clamp_depth / 4)
                    attach_nut_cutout();

                // Screw to go into nut holder on other side
                back(Clamp_depth / 4)
                    left(wall)
                    up(slop/2)
                    position(BOTTOM)
                    cyl(d=Nut_width-slop, h=nut_wall_t,
                        anchor=LEFT,
                        orient=LEFT
                        );
            }
        }
    }
}

module make_mount() {
    // TODO: attach outside rails
    // TODO: figure out how to center the rail
    // TODO: how do I make sure it doesn't wiggle in the Z direction
    down((Clamp_wall_height-wall)/2)
    diff("cutme")
        cuboid([nut_wall_t, ps.y, Nut_width+wall],
               chamfer=chamf,
               anchor=TOP) {
        attach_nut_cutout($tags="cutme");
       };

    // TODO: do something to hold the back of the pcb
    back(50) pcb_back_holder();
}
echo(str("This adds at least ", Nut_width+wall, "mm in height"));

echo(str("Minimum screw length: ", nut_wall_t + Middle_gap + 2*wall, "mm"));


difference() {
    union() {
        make_clamps();
        make_mount();
    }

     down((Clamp_wall_height + wall)/2 + Nut_width / 2) {
         mirror_copy(BACK) fwd(Clamp_depth / 4)
             cyl(orient=RIGHT, h=Power_module_size.x, d=Screw_hole_diameter);
         cyl(orient=RIGHT, h=Power_module_size.x, d=Screw_hole_diameter);
     }
}
