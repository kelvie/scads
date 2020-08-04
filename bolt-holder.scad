
Face_length = 17;
Height = 6.63;
Thickness = 3;
Label = "M10";
Label_font_size = 3;

Number_of_handles = 3;
Handle_radius = 30;


use <lib/addBase.scad>;

// To hide from customizer
module hidden() {
}

diameter = Face_length / cos(30);
$fa=1;
$fs = 0.025;

module cutout() {
    $eps = Height / 1000;
    difference() {
        children(0);
        translate([0, 0, Thickness])
            linear_extrude(Height + $eps)
            circle(d=diameter, $fn=6);
        translate([0, 0, Thickness-0.15]) linear_extrude(0.15)
            text(text=Label, size=Label_font_size, font="Oxygen", halign="center", valign="center");
    }
}

// TODO: Chamfer corners?
// TODO: knurled edges
module main() {
    $eps = Face_length / 1000;
    xyThickness = Thickness*2;
    n = Number_of_handles;
    cutout() linear_extrude(Height + Thickness) difference() {
        circle(r=diameter/2 + xyThickness);
        for (i=[1:n])
            rotate([0, 0, i*360 / n])
                translate([0, Face_length/2 + Handle_radius + Thickness])
                circle(r=Handle_radius);
    }
}

addBase(0.3, 2)
main();
