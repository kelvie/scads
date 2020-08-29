include <../lib/BOSL2/std.scad>

part_to_show = "A"; // [A,B,C]
part_to_hide = "B"; // [A,B,C]


module my_part() {
    tags("A") left(10) cuboid(10);
    tags("B") diff("neg", "B") right(10) {
        cuboid(10);
        cyl(d=10, h=10, $tags="neg");
    }
    tags("C") fwd(10) cuboid(10);
}

show(part_to_show) hide(part_to_hide) my_part();
