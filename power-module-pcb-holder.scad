include <lib/BOSL2/hull.scad>
include <lib/BOSL2/std.scad>

Part_to_show = "All"; // [All, Clamp, Mount, Back holder]
PCB_size = [18.22, 49.2, 1.57];
Power_module_size = [25, 80, 40];

Wall_thickness = 2;

Clamp_wall_height = 5;
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
Show_PCB = true;

/* [hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

width=25;

ps = PCB_size;
wall = Wall_thickness;
chamf = wall / 4;

// Use 1mm walls for these...
nut_wall_t = Nut_thickness + 2;
Clamp_depth = 4*Wall_thickness + 3 * Nut_width;

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
    if (Show_PCB) color("green", 0.2) cuboid(size=ps);
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
nt = Nut_thickness;
nw = Nut_width;
module attach_nut_cutout() {
    position(BOTTOM) down(slop) cuboid([nt, nw, nw] + slop * [1,1,1],
                                       chamfer=-chamf,
                                       edges=BOTTOM,
                                       $tags="cutme",
                                       anchor=BOTTOM);
}

module attach_screw_head_cutout() {
    position(BOTTOM) down(slop) cuboid([nut_wall_t, nw, nw] + slop * [1,1,1],
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


// TODO: reposition screw holes so they can be tapered to print on its side
module make_clamp() {
    // Clamp wall
    diff("cutme")
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

                // For a nut + bolt to clamp the PCB
                left(wall)
                    attach_screw_head_cutout();


                // Nut holder for other side of clamp
                // fwd(Clamp_depth / 4)
                //     attach_nut_cutout();

                // To center the
                back(Clamp_depth / 3)
                    left(wall)
                    attach_screw_head_cutout();
            }
        }
    }
}

module make_mount() {
    // TODO: make this more printable... maybe use vertical mounts somehow
    // TODO: hold nuts in rails somehow
    down((Clamp_wall_height-wall)/2)
        diff("cutme")
        cuboid([nut_wall_t, ps.y, Nut_width+wall],
               chamfer=chamf,
               anchor=TOP) {
        mirror_copy(BACK)
            fwd(Clamp_depth/3) attach_nut_cutout($tags="cutme");

        mirror_copy(BACK) position(FRONT+BOTTOM)
            cuboid([Power_module_size.x, wall, Nut_width+wall],
                   chamfer=chamf,
                   anchor=FRONT+BOTTOM) {
            dy = (ps.y - Clamp_depth)/2 - 2*slop;
            position(FRONT)
                back(dy)
                cuboid(size=$parent_size,
                       chamfer=chamf,
                       anchor=BACK);
                mirror_copy(LEFT) position(RIGHT+FRONT)
                cuboid([wall, dy, Nut_width+wall],
                       chamfer=chamf,
                       anchor=RIGHT+FRONT
                    ) {
                    % position(LEFT) cuboid([2.4, 5.5, 5.5], anchor=RIGHT);
                    tags("cutme") hull() {
                    right(slop) back(wall) position(RIGHT+FRONT)
                        cyl(d=Screw_hole_diameter,
                            h=wall+2*slop,
                            anchor=FORWARD+TOP,
                            orient=RIGHT);
                    right(slop) fwd(wall) position(RIGHT+BACK)
                        cyl(d=Screw_hole_diameter,
                            h=wall+2*slop,
                            anchor=BACK+TOP,
                            orient=RIGHT);
                    }
                }
        }
    };

    // TODO: do something to hold the back of the pcb
}
echo(str("This adds at least ", Nut_width+wall, "mm in height"));

echo(str("Minimum screw length: ", nut_wall_t + Middle_gap + 2*wall + Nut_thickness/2, "mm"));


difference() {
    union() {
        if (Part_to_show == "All") {
            mirror_copy_yflip(LEFT)
                make_clamp();
            make_mount();
            back(max(Power_module_size.y, PCB_size.y + 10)/2) pcb_back_holder();
        } else if (Part_to_show == "Clamp") {
            make_clamp();
        } else if (Part_to_show == "Mount") {
            make_mount();
        } else if (Part_to_show == "Back holder") {
            pcb_back_holder();

        }
    }

    // Cut out screw holes
     down((Clamp_wall_height + wall)/2 + Nut_width / 2) {
         mirror_copy(BACK) fwd(Clamp_depth / 3)
             cyl(orient=RIGHT, h=Power_module_size.x, d=Screw_hole_diameter);
         cyl(orient=RIGHT, h=Power_module_size.x, d=Screw_hole_diameter);
     }
}
