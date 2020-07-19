// c-mount rear lens cap

/* [Overall dimensions] */
// Rim thickness
Outer_Thickness_Min = 1;
Outer_Thickness_Max = 3;

// Overall height
Outer_Height = 5;

// The height of the hole inside
Inner_Height = 1;

/* [Grip] */
Notch_Count = 5;
Notch_Radius = 15;

/* [Label] */
Text = "C-mount rear lens cap";
Font = "Oxygen"; // FONTLIST
Font_Size = 1.5;
Engraving_Depth = 0.3;

/* [Special variables] */
// Fragment count
$fn=200;
// Fudge factor for diffs + unions
$eps=0.01;

use <threads.scad>

module notches(od) {
    inset = Outer_Thickness_Max - Outer_Thickness_Min;
    dx = od/2 + Notch_Radius - inset;
    for (i=[0:Notch_Count])
        rotate([0, 0, i*360/Notch_Count])
            translate([dx, 0, -$eps])
            cylinder(r=Notch_Radius, h=Outer_Height+2*$eps);
}

module innerPart() {
    translate([0, 0, Inner_Height])
        english_thread(diameter=1, threads_per_inch=32, internal=true, length=Outer_Height-Inner_Height, leadin=1);

}

module addLabel() {
    difference() {
        children(0);
        translate([0, 0, Inner_Height - Engraving_Depth])
        linear_extrude(Engraving_Depth+$eps)
            text(text=Text, font=Font, size=Font_Size, halign="center", valign="center");
    }
}

module main() {
    od = 25.4 + 2*Outer_Thickness_Max;

    addLabel() difference() {
        cylinder(h=Outer_Height, d=od);
        innerPart();
        notches(od);
    }
}

main();
