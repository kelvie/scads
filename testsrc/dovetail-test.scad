include <../lib/BOSL2/std.scad>
include <../lib/BOSL2/joiners.scad>
include <../lib/addBase.scad>

wall=2;
chamfer=2/4;

wt = wall;

module edge_dovetail(type, length) {
    dovetail(type,
             length=length,
             height=wt/2,
             width=wt/2,
             chamfer=wt/16,
             spin=180,
             anchor=BOTTOM,
             back_width = 0.9 * wt/2,
             $slop=0.1,
             $tags=$tags
        );
}

module make_dovetail(type, length, taper=1) {
    // TODO: this doesn't look lke it'll fit
    module opposite() {
//            right(length/2)
        yrot(180) dovetail(type == "male" ? "female" : "male",
                           length=length,
                           height=wall/2,
//                               width=wall + 2*length*tan(taper),
                           width=wall,
                           spin=90,
                           chamfer=0,
                           anchor=BOTTOM,
                           taper=taper, $slop=0);
    }
    dovetail(type,
             length=length,
             height=wall/2,
             width=wall,
             spin=90,
             chamfer=0,
             anchor=BOTTOM,
             taper=taper
        );

    tags("mask") opposite();
    %opposite();
}

module base_cube() {
    cuboid(size=[wt, 20, wt],anchor=BOTTOM,
           chamfer=chamfer,
           edges=BOTTOM
        )
        children();
}
base_cube() {
        attach(TOP) edge_dovetail("male", 20);
    }


diff("diff-me")
    left(10) base_cube() {
        tags("diff-me") attach(TOP) edge_dovetail("female", 20);
    }

