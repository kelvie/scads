
Base_Size = [10, 5, 5];
Small_Cut = 0.1;
Medium_Cut = 0.2;
Large_Cut = 0.3;

Row_Max = 6;

Font = "Ubuntu";
Font_Size = 1;
Text_Depth = 0.15;

// min feature size
$fs=0.025;
// angle to render as a single feature in a circle
$fa=3;



module addLabel(label, center) {
    union() {
        children();
        translate(center + [0, -Text_Depth, 0]) rotate([90, 0]) 
            linear_extrude(Text_Depth + $eps)
            text(text=label, font=Font, size=Font_Size, halign="center", valign="center");
    }
}

module makeCube(label) {
    size = Base_Size;
    addLabel(label, [size.x / 2,  0.1, size.z / 2])
        cube(size);
}

$eps=0.01;

// Adds a base to avoid elephant's foot on SLA prints
// when printing Z=0 face downward
// inset defaults to height, chamfer creates a graduation based on $fs
// Optionally take a 2d base as the second child to avoid a
// projection to figure out the shape of the base
module addBase(height, inset=-1, chamfer=false) {
    // epsilon to make sure layers merge without coplanar surfaces
    layers = chamfer ? height / $fs : 1;
    $eps = height / layers / 100;

    for (i = [0:layers-1])
        translate([0, 0, i*height/layers])
            linear_extrude(height/layers + $eps)
            offset(delta=-(inset -i*inset/layers), chamfer=true)
            if ($children > 1)
                children(1);
            else
                projection(cut=true)
                    children(0);

    translate([0, 0, height])
        children(0);
}

xoffset = Base_Size.x + max(Base_Size.x, 2*Base_Size.z);
yoffset = Base_Size.y + max(Base_Size.y, 2*Base_Size.z);

specs = [
    // [height, inset, chamfer]
    [0, 0],
    [0.2, 1],
    [0.3, 1],
    [0.4, 1],
    [0.5, 1],
    [0.2, 1.5],
    [0.4, 1.5],
    [0.2, 2],
    [0.4, 2],
    [0.2, 1, true],
    [0.2, 2, true],
    [0.4, 1, true],
    [0.4, 2, true],
    ];

for (i = [0:len(specs) - 1]) {
    spec = specs[i];
    label = (spec[0] == 0) ?
        "base" :
        str(spec[0], " / ", spec[1], (spec[2]) ? "/" : "");
    translate([(i % Row_Max) * xoffset, floor(i / Row_Max) * yoffset, 0])
        addBase(spec[0], spec[1], spec[2])
        makeCube(label);
}
