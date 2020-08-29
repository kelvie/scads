include <../lib/BOSL2/std.scad>

y = 10.1;
outside = [15, y, 15];
inside = [10, y, 12.5];
chamfer = 0.7;

// Why is this needed?
bosl_fudge_factor = 0;


difference() {
    cuboid(outside, anchor=BACK+BOTTOM, chamfer=chamfer);
    up(outside.z)
        cuboid(inside, anchor=BACK+TOP, $overlap=0) {

        // chamfers parallel to x axis
        edge_mask(edges=[FRONT, BACK], except=[LEFT, RIGHT, TOP])
            chamfer_mask(inside.x - bosl_fudge_factor, chamfer);

        // chamfers parallel to y axis
        edge_mask(edges=TOP, except=[FRONT, BACK])
            chamfer_mask(inside.y - bosl_fudge_factor, chamfer);

        // chamfers parallel to z axis
        edge_mask(edges=[FRONT, BACK], except=[TOP, BOTTOM])
            chamfer_mask(inside.z - bosl_fudge_factor, chamfer);

        // chamfer x-z corners
        intersection()  {
            edge_mask(edges=[FRONT, BACK], except=[LEFT, RIGHT, TOP])
                chamfer_mask(inside.x - bosl_fudge_factor + 2*chamfer, chamfer);
            edge_mask(edges=[FRONT, BACK], except=[TOP, BOTTOM])
                chamfer_mask(inside.z - bosl_fudge_factor + 2*chamfer, chamfer);
        }
    }
}
