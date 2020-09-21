// This adds a h and inset to the part directly on the XYplane (looking
// downward). The idea behind this is to create a elevated base to account for
// the z-compression on the first few layers (which is done) for platform
// adherence on resin printers.
//
// To not have extra resin get cured around the base, on my Formlabs Form 3
// (using black v4 resin), I have to use a h of 0.3 and an inset of 1.5,
// but this adds an extra 0.1mm h after curing.
//
// Parameters:
//
// `enable` is so you can pass in a customizer parameter to easily turn this off
//
// `zcut` cuts the model by `zcut` in the z direction, to help preserve overall
//     z-h if necessary.
module add_base(h=0.3, inset=1.5, zcut=0.1, chamfer=false, enable=true) {
    // epsilon to make sure layers merge without coplanar surfaces
    layers = chamfer ? h / $fs : 1;
    $eps = h / layers / 100;

    // TODO: add custom supports at arbitrary points, though PreForm can do this
    module add_base_with_projection() {

        // TODO: do a hull instead with a thin top and bottom layer
        for (i = [0:layers-1])
            translate([0, 0, i*h/layers])
                linear_extrude(h/layers + $eps)
                offset(delta=-(inset -i*inset/layers), chamfer=true)
                children(1);

        translate([0, 0, h])
            if (zcut ==  0) {
                children(0);
            } else {
                translate([0, 0, -zcut]) {
                    difference() {
                        children(0);
                        translate([0, 0, -h])
                            linear_extrude(zcut + h)
                            offset(delta=4*zcut)
                            children(1);
                    }
                }
            }
    }

    if (enable)
        add_base_with_projection() {
            children(0);

            if ($children > 1)
                children(1);
            else
                projection(cut=true)
                    down($fs/10) // for some reason projection fails sometimes if it's not *exactly* on the x-axis
                    children(0);
        }
    else
        children(0);

}


// TODO: remove this and use add_base instead
module addBase(h, inset=-1, chamfer=false, enable=true, zoff=0) {
    add_base(h, inset, zoff, chamfer, enable)
        children();
}
