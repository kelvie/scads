
Base_Size = [3, 2, 2];
Small_Cut = 0.1;
Medium_Cut = 0.2;
Large_Cut = 0.3;

Font = "Ubuntu";
Font_Size = 1;
$eps = 0.01;


module addLabel(label, center) {
    union() {
        children();
        translate(center + [0, 0, Base_Size.z-$eps])
            linear_extrude(0.1+ $eps)
            text(text=label, font=Font, size=Font_Size, halign="center", valign="center");
    }
}

module makeCube(label) {
    size = Base_Size;
    addLabel(label, [size.x / 2, size.y / 2, 0])
        cube(size);
}


// Shorthand
sz = Base_Size;

module cutBottom(amount, inf=5) {

}


// inf is some large number that should be larger than the part to cut
module bottomCut(height, cut, inf=5) {
    union() {
        // Slice off the bottom
        difference() {
            children(0);
            translate([-inf, -inf, -$eps]) cube([2*inf, 2*inf, height + 2*$eps]);
        }
        // Add a new one
        translate(cut * [1, 1, 0]) cube([sz.x - 2*cut, sz.y - 2*cut, height + $eps ]);
    }
}

module addBottom(height, cut) {
    union() {
        translate([0, 0, height]) children(0);
        translate(cut * [1, 1, 0]) cube([sz.x - 2*cut, sz.y - 2*cut, height + $eps ]);
    }
}


// baseline
makeCube("B");

// tall, medium cut
translate([sz.x + 2, 0, 0])
addBottom(0.2, Medium_Cut) makeCube("tm");

// really tall, medium cut
translate([(sz.x + 2)*2, 0, 0])
addBottom(0.4, Medium_Cut) makeCube("rtm");

// small cut
translate([0, sz.y + 2, 0])
bottomCut(0.05, Small_Cut) makeCube("S");


// medium cut
translate([sz.x + 2, sz.y + 2, 0])
bottomCut(0.05, Medium_Cut) makeCube("M");

// large cut
translate([2*(sz.x + 2), sz.y + 2, 0])
bottomCut(0.05, Large_Cut) makeCube("L");

