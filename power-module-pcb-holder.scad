include <lib/BOSL2/hull.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/metric_screws.scad>

include <lib/add-base.scad>

/* [Overall dimensions] */
PCB_size = [18.22, 49.2, 1.57];
Power_module_size = [25, 80, 40];

// Minimum wall thickness -- non-load bearing walls can be half this
Wall_thickness = 2;

/* [Clamp dimensions] */
Clamp_wall_height = 8;
Clamp_wall_thickness = 2;
Clamp_depth = 15;

/* [Base mount dimensions] */
Back_plate_height = 8;
Back_plate_width = 10;

// Size of the lugs on the grips
Grip_size = 0.6; // [0:0.1:2]

Middle_pillar_size = 3;

/* [Nuts and bolts] */

// Assumes square nuts
Nut_width = 5.5;
Nut_thickness = 2.4;

Screw_size = 3;
Screw_hole_diameter = 3.2;
Screw_head_height = 1.65;

// Only affects the bottom screw rail
Screw_head_type = "Countersunk"; // [Countersunk, Pan head]

// Extra tolerance for push-in nuts, etc.
Slop = 0.075;

// Tolerance for a loose slide fit (like for rails)
Loose_slop = 0.125;


/* [Visibility] */

Part_to_show = "All"; // [All, Clamp, Mount]

// Only when showing all parts
Show_power_module_dimensions = false;

// Only when showing all parts
Show_PCB = true;

/* [Printability] */
// Add a raised base for printing directly on the build platform
Add_base = true;

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;

ps = PCB_size;
wall = Wall_thickness;
chamf = wall / 4;

// This includes two 1mm walls, should be OK
nut_wall_t = Nut_thickness + 2;

// Creates a grip mask
module grip_mask(size, anchor=CENTER, spin=0, orient=TOP) {
    sz = [size.x, size.y, size.z*sqrt(2)];

    xsegments = floor(sz.x / sz.z);
    ysegments = floor(sz.y / sz.z);

    // debug
    // %cuboid(new_sz, anchor=anchor, spin=spin, orient=orient);

    attachable(size=sz, anchor=anchor, spin=spin, orient=orient) {
        union() {
            xcopies(spacing=sz.z, n=xsegments)
                yrot(45) cuboid([size.z, size.y, size.z]);
            ycopies(spacing=sz.z, n=ysegments)
                xrot(45) cuboid([size.x, size.z, size.z]);
        }
        children();
    }
}

// shortcuts
slop = Slop;
nt = Nut_thickness;
nw = Nut_width;

// TODO: clamp doesn't work great for keeping boards in the z direction.
// TODO: consider somehow allowing two boards at once
module clamp_part(anchor=CENTER, spin=0, orient=TOP) {
    eps= $fs/10;

    diff("cutme")
        cuboid(size=[nw + wall, Clamp_depth, nt+wall],
               anchor=anchor, spin=spin, orient=orient,
               chamfer=chamf
            ) {
        tags("cutme") {

            nut_sz = [nw+eps, nw, nt] + slop * [1,1,1];
            taper_angle = 8;
            taper_height = nut_sz.y / 2 * tan(taper_angle) ;
            // Square nut nolder cutout
            position(LEFT)
                left(eps)
                cuboid(nut_sz,
                       anchor=LEFT) {
                // Taper up the square nut to ease printing
                position(TOP)
                    down(eps)
                    prismoid(size1=[nut_sz.x, nut_sz.y],
                    size2=[nut_sz.x, 0],
                    h=taper_height+eps);
            }

            // Cutout for screw hole
            position(LEFT+BOTTOM)
                right(nw/2)
                    down(eps)
                    cyl(h=$parent_size.z + Clamp_wall_height/2 + eps, d=Screw_hole_diameter,
                         anchor=BOTTOM, chamfer2=Screw_hole_diameter/8);
        }
        position(LEFT+BOTTOM)
            cuboid([Clamp_wall_thickness, Clamp_depth, Clamp_wall_height+$parent_size.z],
                   chamfer=chamf,
                   anchor=LEFT+BOTTOM
                ) {
            // Make the clamp wall grippy
            if (Grip_size > 0)
                down(chamf)
                position(RIGHT+TOP)
                    grip_mask([Clamp_wall_height-chamf, Clamp_depth, Grip_size],
                              orient=RIGHT, anchor=LEFT,
                               $tags="cutme");
            }


    }
}

side_mount_sz = [Power_module_size.x,
                 (ps.y - Clamp_depth)/2 - Loose_slop,
                 nw + wall];

// Side mounts for the whole piece to mount onto the power module
// FUTURE: rect pipe instead?
// TODO: make one that mounts downward and is less tall for slimmer PCBs
module side_mounts(inner_width, anchor=CENTER, spin=0, orient=TOP) {
    sz = side_mount_sz;
    eps = $fs/2;

    attachable(size=sz, anchor=anchor, spin=spin, orient=orient) {
        fwd(sz.y/2)
            // Front plate
            cuboid([sz.x, wall, sz.z],
                   anchor=FRONT,
                   chamfer=chamf) {

            position(FRONT)
                back(sz.y)
                cuboid(size=$parent_size,
                       chamfer=chamf,
                       anchor=BACK);

            // Side plates
            mirror_copy(LEFT)
                position(RIGHT+FRONT)
                diff("cutme")
                cuboid([wall, sz.y, sz.z],
                       chamfer=chamf,
                       anchor=RIGHT+FRONT
                    ) {
                // Show where the nut would go
                % position(LEFT) cuboid([nt, nw, nw], anchor=RIGHT);

                // Wall to hold nut in place; 2 * slop for a looser fit
                position(LEFT)
                 left(nt + 2*slop)
                    cuboid($parent_size,
                           chamfer=chamf,
                           anchor=RIGHT);

                // Add bottom wall to hold nut
                position(BOTTOM+LEFT)
                    right(chamf)
                    cuboid([nt + 2*slop + 2*chamf, sz.y - wall, ($parent_size.z - nw) / 2 - 2*slop],
                           anchor=BOTTOM+RIGHT
                        );

                // Screw hole for the rail
                tags("cutme")
                    hull() {
                    right(eps) back(wall + nw/2) position(RIGHT+FRONT)
                        cyl(d=Screw_hole_diameter,
                            h=2*wall + nt + 2*slop + 2*eps,
                            anchor=TOP,
                            orient=RIGHT);
                    right(eps) fwd(wall + nw/2) position(RIGHT+BACK)
                        cyl(d=Screw_hole_diameter,
                            h=2*wall + nt + 2*slop + 2*eps,
                            anchor=TOP,
                            orient=RIGHT);
                }
            }
        }
        children();
    }
}

mount_height = max(wall, Screw_head_height + wall/2);
rail_width = Power_module_size.x -
    2*(Screw_head_height + Screw_hole_diameter/2 + chamf + slop);

module x_rail() {
    eps=$fs/4;

    dx = rail_width / 2;
    tags("cutme") {
        // screw rail
        up(eps)
            position(TOP) {
            hull()
                mirror_copy(LEFT)
                left(dx)
                cyl(d=Screw_hole_diameter, h=$parent_size.z, anchor=TOP);

            hull()
                mirror_copy(LEFT)
                left(dx)
                down($parent_size.z + 2*eps)
                cyl(d1=Screw_size+2*Screw_head_height,
                    d2=Screw_size,
                    h=Screw_head_height + eps,
                    anchor=BOTTOM);
        }
    }

}

module make_mount() {
    eps=$fs/4;

    diff("cutme", "bottom", keep="keepme")
        down(side_mount_sz.z)
        cuboid([Power_module_size.x, ps.y - 2*side_mount_sz.y + wall, mount_height],
               chamfer=chamf,
               anchor=BOTTOM, $tags="bottom") {

        // TODO: dual rail?
        //mirror_copy(BACK) fwd($parent_size.y / 4)
        x_rail();

        // Middle pillar, if desired
        if (Middle_pillar_size > 0)
            position(BOTTOM)
            cuboid([Middle_pillar_size, ps.y, side_mount_sz.z], anchor=BOTTOM,
                chamfer=chamf, $tags="keepme");

        fwd(wall/2)
            position(BACK+BOTTOM)
            side_mounts(anchor=FRONT+BOTTOM) {
            // Hold the back of the PCB in place
            position(BACK+TOP)
                down(chamf)
                cuboid([Back_plate_width, wall, Back_plate_height + chamf + slop],
                       anchor=BOTTOM+BACK,
                       chamfer=chamf,
                       edges=edges("ALL", except=BOTTOM)
                    );
                }

        back(wall/2)
            position(FRONT+BOTTOM)
            side_mounts(anchor=BACK+BOTTOM);
    }
}

union() {
    if (Part_to_show == "All") {
        make_mount();

        zrot_copies(n=2)
            left(Power_module_size.x/2 - nw/2 - wall/2 - (nw - Screw_hole_diameter)/2) {
            down(side_mount_sz.z - mount_height) clamp_part(anchor=BOTTOM);
        }

    } else if (Part_to_show == "Clamp") {
        add_base(0.3, 1, 0.1, enable=Add_base)
            clamp_part(anchor=BOTTOM);
    } else if (Part_to_show == "Mount") {
        add_base(0.3, 1, 0.1, enable=Add_base)
            up(side_mount_sz.z)
            make_mount();
    }
}

if ($preview && Part_to_show == "All") {

    mirror_copy(LEFT)
    down(side_mount_sz.z)
        left(Power_module_size.x / 2 - nw/2 - wall/2)
        color("gray", 0.7)
        metric_bolt(headtype="countersunk", size=3, l=8, orient=BOTTOM,
                    phillips="#1", pitch=0, anchor=TOP);

    // PCB
    if (Show_PCB)
        color("green", 0.5)
            up(Clamp_wall_height/2)
            fwd(wall)
            cuboid(size=ps);
    if (Show_power_module_dimensions) %cuboid(Power_module_size);
}

echo(str("This adds ", side_mount_sz.z, "mm to the height."));
echo(str("Rail size is ", side_mount_sz.y - 2*wall - nw, "mm"));
$export_suffix = Part_to_show;
