include <lib/BOSL2/hull.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/partitions.scad>

Part_to_show = "All"; // [All, Clamp, Clamp - top, Clamp - bottom, Mount, Back holder: Back holder - unused]
PCB_size = [18.22, 49.2, 1.57];
Power_module_size = [25, 80, 40];

Wall_thickness = 2;

Clamp_wall_height = 5;
Clamp_wall_thickness = 2;

Back_plate_height = 5;
Back_plate_width = 10;

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

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

width=25;

ps = PCB_size;
wall = Wall_thickness;
chamf = wall / 4;

// This includes two 1mm walls, should be OK
nut_wall_t = Nut_thickness + 2;
Clamp_depth = 4*Wall_thickness + 3 * Nut_width;

module pcb_back_holder() {
    // This will hold up the PCB from the back side, but will need to be screwed
    // in with a M3 screw. Unused currently.
    diff("cutme")
        cyl(d=5, h=3, orient=FRONT) {
        attach(BOTTOM) cyl(d=3.5, h=$parent_size.z);
        attach(BOTTOM) cyl(d=3.1, h=$parent_size.z+0.01, $tags="cutme");
        attach(TOP) back($parent_size.y/2) down(1)
            cuboid($parent_size, anchor=BOTTOM, $tags="cutme");
    };
}

if ($preview) {
    if (Show_power_module_dimensions) %cuboid(Power_module_size);

    // PCB
    if (Show_PCB)
        color("green", 0.2)
            fwd(wall)
            cuboid(size=ps, anchor=BOTTOM);
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
    position(BOTTOM) down(slop) cuboid([nt, nw, 2*nw] + slop * [1,1,1],
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

module mirror_copy_yflip(v) {
    children(0);
    mirror(v) mirror(FORWARD) children(0);
}

// TODO: 7 nuts for a single PCB seems a bit nuts, maybe consider snaps or
//       something 3d printed
// TODO: Or consider using screws in the z direction to mount to the power
//       module casing, and use an adjustable spacer for the Z-spacing of the
//       USB port
module make_clamp_side() {
    // Clamp wall
    diff("cutme")
        left(ps.x / 2)
        down(wall)
        cuboid([clt, Clamp_depth, Clamp_wall_height+wall],
               chamfer=chamf,
               edges=edges("ALL", except=BOTTOM+RIGHT),
               anchor=RIGHT+BOTTOM) {

        // Make the clamp wall grippy
        up(wall/2) attach(RIGHT, $overlap=0)
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

                // Screws for centering the clamps within the mount
                back(Clamp_depth / 3)
                    left(wall)
                    attach_screw_head_cutout();
            }
        }
    }
}

module make_mount() {
        diff("cutme")
        cuboid([nut_wall_t, ps.y, Nut_width+wall],
               chamfer=chamf,
               anchor=TOP) {

            // Hold the back of the PCB in place
            position(BACK+TOP)
                down(chamf + slop)
                cuboid([Back_plate_width, wall, Back_plate_height + chamf + slop],
                       anchor=BOTTOM+BACK,
                       chamfer=chamf,
                       edges=edges("ALL", except=BOTTOM)
                    );

        mirror_copy(BACK)
            fwd(Clamp_depth/3) attach_nut_cutout($tags="cutme");

        mirror_copy(BACK) position(FRONT+BOTTOM)
            cuboid([Power_module_size.x, wall, Nut_width+wall],
                   chamfer=chamf,
                   anchor=FRONT+BOTTOM) {


            // Create rails to mount onto the side of the power module
            dy = (ps.y - Clamp_depth)/2 - 2*slop;
            position(FRONT)
                back(dy)
                cuboid(size=$parent_size,
                       chamfer=chamf,
                       anchor=BACK);
                mirror_copy(LEFT)
                    position(RIGHT+FRONT)
                    cuboid([wall, dy, Nut_width+wall],
                            chamfer=chamf,
                            edges=edges("ALL", except=LEFT),
                            anchor=RIGHT+FRONT
                    ) {
                    // Show where the nut would go
                    % position(LEFT) cuboid([nt, nw, nw], anchor=RIGHT);

                    // Add guides for the nut
                    mirror_copy(TOP)
                    position(TOP+LEFT)
                        cuboid([nt/2, dy - wall, ($parent_size.z - nw) / 2 - slop],
                               anchor=TOP+RIGHT
                            );

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
}
echo(str("This adds at least ", Nut_width+wall, "mm in height"));

echo(str("Minimum screw length: ", nut_wall_t + Middle_gap + 2*wall + Nut_thickness/2, "mm"));

module clamp_mask() {
    left(ps.x / 4 + wall + wall/2 - 0.1)
    back(Clamp_depth/2)
        down(wall/2)
        partition_mask(l=(ps.x - nut_wall_t - Middle_gap)/2 + wall + 0.2,
                       h=Clamp_depth,
                       w=wall + Clamp_wall_height,
                       cutpath="jigsaw",
                       cutsize=wall/4,
                       orient=FRONT,
                       $slop=0.1
            );
}

difference() {
    union() {
        if (Part_to_show == "All") {
            zrot_copies(n=2)
                make_clamp_side();
            make_mount();
            // No longer necessary
            // back(PCB_size.y/2 + 5) pcb_back_holder();
        } else if (Part_to_show == "Clamp") {
                make_clamp_side();
        } else if (Part_to_show == "Clamp - top") {
            intersection() {
                make_clamp_side();
                clamp_mask();
            }
        } else if (Part_to_show == "Clamp - bottom") {
            difference() {
                make_clamp_side();
                clamp_mask();
            }
        } else if (Part_to_show == "Mount") {
            make_mount();
        } else if (Part_to_show == "Back holder") {
            pcb_back_holder();
        }
    }

    // Cut out screw holes
     down(wall + Nut_width / 2) {
         mirror_copy(BACK) fwd(Clamp_depth / 3)
             cyl(orient=RIGHT, h=Power_module_size.x, d=Screw_hole_diameter);
         cyl(orient=RIGHT, h=Power_module_size.x, d=Screw_hole_diameter);
     }
}
