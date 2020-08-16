// This adds a height and inset to the part directly on the XYplane (looking
// downward). The idea behind this is to create a elevated base to account for
// the z-compression on the first few layers (which is done) for platform
// adherence on resin printers.
//
// To not have extra resin get cured around the base, on my Formlabs Form 3
// (using black v4 resin), I have to use a height of 0.3 and an inset of 1.5,
// but this adds an extra 0.1mm height after curing.
//
// Enable is so you can pass in a customizer parameter to easily turn this off
module addBase(height, inset=-1, chamfer=false, enable=true) {
    // epsilon to make sure layers merge without coplanar surfaces
    layers = chamfer ? height / $fs : 1;
    $eps = height / layers / 100;

    // TODO: do a hull instead with a thin top and bottom layer
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
