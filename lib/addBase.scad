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
