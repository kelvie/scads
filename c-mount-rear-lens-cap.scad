// c-mount rear lens cap

// Increase to add "snug"ness
Inner_Diameter_Diff = 0.02;
Outer_Thickness = 1.5;

// Overall height
Outer_Height = 5;

// The height of the hole inside
Inner_Height = 4;

$fn=200;

module main() {
    epsilon = 0.001;

    id = 25.4 - Inner_Diameter_Diff;
    od = 25.4 + 2*Outer_Thickness;

    difference() {
        cylinder(h=Outer_Height, d=od);
        translate([0, 0, 1])
            cylinder(h=Inner_Height+epsilon, d=id);
    }
}

main();
