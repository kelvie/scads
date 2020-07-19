// c-mount rear lens cap

/* [Overall dimensions] */
// Rim thickness
Outer_Thickness_Min = 1;
Outer_Thickness_Max = 3;

// Overall height
Outer_Height = 5;

// The height of the hole inside
Inner_Height = 1;

// Extra thread clearance in case it's too tight
Extra_Thread_Clearance = 0.1;

// Extra height to add to the bottom if printing directly on the platform (for SLA printers). Set to 0 to disable
Platform_Print_Height = 0.2;

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
    clearanceInInches = Extra_Thread_Clearance / 25.4;
    lengthInInches = (Outer_Height-Inner_Height+$eps) / 25.4 ;
    translate([0, 0, Inner_Height])
        english_thread(diameter=1+clearanceInInches, threads_per_inch=32, internal=true, length=lengthInInches, leadin=1);

}

module addLabel() {
    difference() {
        children(0);
        translate([0, 0, Inner_Height - Engraving_Depth])
        linear_extrude(Engraving_Depth+$eps)
            text(text=Text, font=Font, size=Font_Size, halign="center", valign="center");
    }
}

module addPlatform(height, inset, od) {
    // Scale factor
    sf = 1 - inset/od*2;
    if (Platform_Print_Height > 0 ) union() {
        translate([0, 0, height]) children(0);
        scale([sf, sf, 1])
            outerShape(od, height+$eps);
    } else {
        children(0);
    }
}

module outerShape(od, height) {
    difference() {
        cylinder(h=height, d=od);
        notches(od);
    }
}

module mainPart(od) {
    addLabel() difference() {
        outerShape(od, Outer_Height);
        innerPart();
    }
}

od = 25.4 + 2*Outer_Thickness_Max;

addPlatform(Platform_Print_Height, 1, od) mainPart(od);
