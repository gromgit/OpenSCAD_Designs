/* [Part Selection] */
object = 1; //[1:Base,2:Drawer,3:Flat Top,4:Tray Top]

/* [Drawer Parameters] */

// drawer height (internal)
drawer_height = 20;
// drawer width (internal)
drawer_width = 180;
// drawer depth (internal)
drawer_depth = 125;
// number of drawer columns
drawer_cols = 1;
// number of drawer rows
drawer_rows = 1;

// handle width
handle_width = 38;
// handle depth
handle_depth = 14;

/* [Tray Parameters] */

// tray height
tray_height = 15;

/* [Hidden] */

$fn = 60;

layer_height = 0.28;
line_width = 0.5;
base_layers = 7;
base_walls = 4;
drawer_layers = 3;
drawer_walls = 3;
drawer_comp_walls = 2;
drawer_comp_wall_width = drawer_comp_walls * line_width;
drawer_comp_col_space = (drawer_width - (drawer_cols - 1) * drawer_comp_wall_width) / drawer_cols;
drawer_comp_row_space = (drawer_depth - (drawer_rows - 1) * drawer_comp_wall_width) / drawer_rows;
tray_layers = 3;
tray_walls = 3;
rounding_radius = 4;
nub_radius = 2;

// derived dimensions
drawer_ext_height = drawer_height + drawer_layers * layer_height;
drawer_ext_width = drawer_width + 2 * drawer_walls * line_width;
drawer_ext_depth = drawer_depth + 2 * drawer_walls * line_width;

// Give 1 layer/line space all around
base_int_height = drawer_ext_height + layer_height;
base_int_width = drawer_ext_width + 2 * line_width;
base_int_depth = drawer_ext_depth + 2 * line_width;

base_ext_height = base_int_height + base_layers * layer_height;
base_ext_width = base_int_width + 4 * rounding_radius;
base_ext_depth = base_int_depth + base_walls * line_width;

tray_base_height = tray_layers * layer_height;
tray_wall_width = tray_walls * line_width;

module lozenge(radius, length)
{
    union()
    {
        circle(radius);
        translate([length - 2 * radius, 0, 0]) circle(radius);
        translate([0, -radius, 0]) square([length - 2 * radius, radius*2]);
    }
}

module rounded_rect(length, width, radius)
{
    // Make the four corners
    translate([radius,radius,0]) circle(radius);
    translate([length-radius,radius,0]) circle(radius);
    translate([length-radius,width-radius,0]) circle(radius);
    translate([radius,width-radius,0]) circle(radius);
    // and the two component rectangles
    translate([radius,0,0]) square([length-2*radius,width]);
    translate([0,radius,0]) square([length,width-2*radius]);
}

module base_frame()
{
    union()
    {
        // Make the side walls
        lozenge(rounding_radius, base_ext_depth);
        translate([0, base_ext_width - 2 * rounding_radius, 0]) lozenge(rounding_radius, base_ext_depth);
        
        // Make the back wall
        translate([-rounding_radius, 0, 0]) square([2, base_ext_width - 2 * rounding_radius]);
        
        // Square off the wall interfaces
        translate([-rounding_radius, 0, 0]) square(rounding_radius);
        translate([-rounding_radius, base_ext_width - 3 * rounding_radius, 0]) square(rounding_radius);
    }
}

module nubs(int_width, int_depth)
{
    out_depth = int_depth - rounding_radius;
    out_width = int_width + rounding_radius * 2;

    linear_extrude(nub_radius)
    union()
    {
        circle(nub_radius);
        translate([out_depth,0,0]) circle(nub_radius);
        translate([out_depth,out_width,0]) circle(nub_radius);
        translate([0,out_width,0]) circle(nub_radius);
    }
}

module base()
{
    difference()
    {
        union() 
        {
            // Walls
            linear_extrude(base_ext_height) base_frame();
            // Base
            linear_extrude(base_layers * layer_height) translate([-rounding_radius, 0, 0]) square([base_ext_depth, base_ext_width - 2 * rounding_radius]);
            translate([0,0,base_ext_height]) nubs(base_int_width, base_int_depth - rounding_radius);
        }
        union()
        {
            linear_extrude(base_layers * layer_height) translate([5, 10 + rounding_radius, 0]) rounded_rect(base_int_depth - 20, base_int_width - 20, rounding_radius * 2);
            nubs(base_int_width, base_int_depth - rounding_radius);
        }
    }
}

module drawer()
{
    union()
    {
        // Main drawer body
        difference()
        {
            translate([-(drawer_walls * line_width), -(drawer_walls * line_width), -(drawer_layers * layer_height)]) linear_extrude(drawer_ext_height) square([drawer_ext_depth, drawer_ext_width]);
            linear_extrude(drawer_height) square([drawer_depth, drawer_width]);
        }
        // Internal compartments
        drawer_compartments();
        // Handle
        translate([drawer_depth + drawer_walls * line_width, (drawer_width - handle_width) / 2 + handle_width, (drawer_height - handle_depth) / 2 + handle_depth]) 
        drawer_handle();
    }
}

module drawer_compartments()
{
    linear_extrude(drawer_height)
    union()
    {
        if (drawer_rows > 1)
        {
            for (i=[2:drawer_rows])
            {
                translate([(i-1)*(drawer_comp_row_space + drawer_comp_wall_width) - drawer_comp_wall_width, 0, 0])
                square([drawer_comp_wall_width, drawer_width]);
            }
        }
        if (drawer_cols > 1)
        {
            for (i=[2:drawer_cols])
            {
                translate([0, (i-1)*(drawer_comp_col_space + drawer_comp_wall_width) - drawer_comp_wall_width, 50])
                square([drawer_depth, drawer_comp_wall_width]);
                echo("col_square: ", drawer_depth,  drawer_comp_wall_width);
            }
        }
    }
}

module drawer_handle()
{
    knob_radius = handle_depth / 6;
    rotate(a=[90,90,0]) linear_extrude(handle_width) union()
    {
        polygon([[0,0],[handle_depth,0],[0,handle_depth]]);
        translate([0,handle_depth - knob_radius,0]) difference() 
        {
            circle(knob_radius);
            translate([0,-knob_radius,0]) square(knob_radius * 2);
        }
    }
}

module top_plate()
{
    difference()
    {
        // Simple plate
        linear_extrude(tray_base_height)
        rounded_rect(base_ext_depth, base_ext_width, rounding_radius);
        
        // Bottom nubs
        translate([rounding_radius, rounding_radius, 0])
        nubs(base_int_width, base_int_depth - rounding_radius);
    }
}

module top_tray()
{
    
    union()
    {
        top_plate();
        difference()
        {
            // Tray block
            linear_extrude(tray_height)
            rounded_rect(base_ext_depth, base_ext_width, rounding_radius);
            
            // Front slope
            translate([base_ext_depth,0,tray_base_height+tray_height])
            rotate([0,90,90])
            linear_extrude(base_ext_width)
            polygon([[0,0],[tray_height,0],[0,tray_height]]);
            
            // Internal box
            translate([tray_wall_width, tray_wall_width,0])
            linear_extrude(tray_height)
            rounded_rect(base_ext_depth - 2 * tray_wall_width, base_ext_width - 2 * tray_wall_width, rounding_radius);
        }
    }
}

module create_part()
{
    if (object==1)
        base();
    if (object==2)
        drawer();
    if (object==3)
        top_plate();
    if (object==4)
        top_tray();
}

rotate([0,0,-90])
create_part();