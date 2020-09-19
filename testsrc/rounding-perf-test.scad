include <../lib/BOSL2/std.scad>

/* [Hidden] */
$fs = 0.025;
// $fa = $preview ? 10 : 5;

// Basically, this will make the cube larger on faces that don't have a edge.
function rounding_size_offset(size, edges, rounding, offset=[0,0,0], i=0, axis=0) =
    (axis == 3) ? [size + vabs(offset) * rounding, offset * rounding/2] :
    (edges[axis][i] == 0) ? rounding_size_offset(size=size,
                                                 offset=offset + rounding * EDGE_OFFSETS[axis][i]/4,
                                                 edges=edges,
                                                 rounding=rounding,
                                                 axis=i == 3 ? axis + 1 : axis,
                                                 i=(i+1) % 4) :
    rounding_size_offset(size=size, offset=offset, edges=edges, rounding=rounding,
                         axis=i == 3 ? axis + 1 : axis,
                         i=(i+1) % 4);

module edge_masks(size, rounding=0, trimcorners=true, edges=EDGES_ALL) {
    majrots = [[0,90,0], [90,0,0], [0,0,0]];
    for (i = [0:3], axis=[0:2]) {
        if (edges[axis][i]>0) {
                translate(vmul(EDGE_OFFSETS[axis][i], size/2)) {
                    rotate(majrots[axis]) cube([rounding*2, rounding*2, size[axis]+0.1], center=true);
            }
        }
    }

    // Round triple-edge corners.
    if (trimcorners) {
        for (za=[-1,1], ya=[-1,1], xa=[-1,1]) {
            if (corner_edge_count(edges, [xa,ya,za]) > 2) {
                translate(vmul([xa,ya,za], size/2)) {
                    cube(rounding*2, center=true);
                }
            }
        }
    }
}

module part(anchor=CENTER, spin=0, orient=TOP) {
    size = [10, 10, 10];
    wall = 2;
    rounding = wall/2;

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        union() {
        cuboid([wall, size.y, size.z],
               rounding=rounding,
               edges=edges("ALL", except=BOTTOM));

        left(size.x/2)
            cuboid([wall, size.y, size.z],
                   rounding=rounding);
        }

        children();
    }
}

module part2(anchor=CENTER, spin=0, orient=TOP) {
    size = [10, 10, 10];
    wall = 2;
    rounding = wall/2;
    edges=edges("ALL", except=[LEFT, BOTTOM]);
    echo("edges are", edges);


    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        intersection() {
            sz_offset = rounding_size_offset(size=[wall, size.y, size.z], edges=edges, rounding=rounding);
            echo(sz_offset);
            translate(sz_offset[1]) cuboid(sz_offset[0], rounding=rounding);
            cuboid([wall, size.y, size.z]);
        }

        children();
    }
}

module part3(anchor=CENTER, spin=0, orient=TOP, edges=edges(RIGHT+FRONT)) {
    size = [5, 5, 5];
    rounding = 1;
    echo(edges);

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        cuboid(size, rounding=rounding, edges=edges);

        children();
    }
}


echo("right+front");
part3(edges=RIGHT+FRONT);

echo("right")
left(15) part3(edges=RIGHT);


echo("all except left")
right(15)
part3(edges=edges("ALL", except=LEFT));

 echo("all except left+top")
 up(15) part3(edges=edges("ALL", except=[LEFT, TOP]));
