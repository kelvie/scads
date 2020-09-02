include <../lib/BOSL2/std.scad>
include <../lib/BOSL2/joiners.scad>
include <../lib/addBase.scad>
include <../lib/text.scad>


slop=0.2; // [0:0.05:0.3]
wt=2;
chamfer=wt/3;
back_width_multiplier=0.9;

$fs= 0.025;
$fa = $preview ? 10 : 5;

module edge_dovetail(type, length) {
    dovetail(type,
             length=length,
             height=wt/2,
             width=wt/2,
             chamfer=wt/16,
             spin=180,
             anchor=BOTTOM,
             back_width=back_width_multiplier*wt/2,
             $slop=slop,
             $tags=$tags
        );
}


module base_cube() {
    addBase(0.3, 1.5, zoff=0.1)
        difference() {
        cuboid(size=[wt*4, 20, wt], chamfer=chamfer, edges=BOTTOM, anchor=BOTTOM)
            children();
        zrot(90) up(wt) addText(str("sl ", slop, " bm ", back_width_multiplier));
    }
}

base_cube() {
    mirror_copy(LEFT)
        attach(TOP)
        left(($parent_size.x - wt)/2)
        edge_dovetail("male", 20);
}

left(15)
diff("diff-me")
base_cube() {
    tags("diff-me")
        mirror_copy(LEFT)
        attach(TOP)
        left(($parent_size.x - wt)/2)
        edge_dovetail("female", 20);
}



$export_suffix = str("slop-", slop, "-bwm-", back_width_multiplier);
