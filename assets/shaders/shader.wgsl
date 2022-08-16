#import bevy_pbr::mesh_view_bindings


@group(1) @binding(0)
var<uniform> camera_pos: vec3<f32>;
@group(1) @binding(1)
var<uniform> camera_dir: vec3<f32>;
@group(1) @binding(2)
var<uniform> focal_len: f32;
@group(1) @binding(3)
var<uniform> power: f32;

let epsilon = 0.0005;
let color_a = vec3<f32>(0.5, 2.0, 2.2);
let color_b = vec3<f32>(0.1, 0.2, 0.4);

// fn sphere_dist(p: vec3<f32>, c: vec3<f32>, r: f32) -> f32 {
//     return length(p - c) - r;
// }


fn myatan(x: f32) -> f32 {
    let absx = abs(x);
    if absx > 1.4656 {
        var sign = 1.0;
        if x < 0.0 {
            sign = -1.0;
        }
        return sign * (1.5707963268 - (1.0/absx) + (1.0/(3.0 * absx * absx * absx)) - (1.0/(5.0 * absx * absx * absx * absx * absx)));
    }
    return 0.7853981634 * x + 0.273 * x * (1.0 - absx);
}

fn mandlebulb(p: vec3<f32>) -> vec2<f32> {
    var zp = vec3<f32>(p.xyz);
    var dr = 1.0;
    var r = 0.0;

    var i = 0u;
    for(i = 0u; i < 15u; i++) {
        r = length(zp);
        if r > 2.0 {
            break;
        }
        let theta = acos(zp.z / r) * power;
        let phi = myatan(zp.y / zp.x) * power;
        dr = pow(r, power - 1.0) * power * dr + 1.0;
        let zr = pow(r, power);
        
        zp = zr * vec3<f32>(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
        zp += p;
    }

    let dist = 0.5 * log(r) * r / dr;
    return vec2<f32>(dist, f32(i));
}

// fn spheres(p: vec3<f32>) -> vec2<f32> {
//     let d1 = sphere_dist(p, vec3<f32>(1.5, 0.0, 0.0), 3.0);
//     let d2 = sphere_dist(p, vec3<f32>(-1.5, 1.0, 1.0), 2.0);
//     let d3 = sphere_dist(p, vec3<f32>(3.0, -3.0, -0.5), 1.2);
//     return vec2<f32>(min(d1, min(d2, d3)), 1.0);
// }

// fn scene_dist(p: vec3<f32>) -> vec2<f32> {
//     // return spheres(p);
//     return mandlebulb(p);
// }

fn calc_normal(p: vec3<f32>) -> vec3<f32> {
    let e = epsilon * 0.1;
    let x = mandlebulb(vec3<f32>(p.x + e, p.y, p.z)).x - mandlebulb(vec3<f32>(p.x - e, p.y, p.z)).x;
    let y = mandlebulb(vec3<f32>(p.x, p.y + e, p.z)).x - mandlebulb(vec3<f32>(p.x, p.y - e, p.z)).x;
    let z = mandlebulb(vec3<f32>(p.x, p.y, p.z + e)).x - mandlebulb(vec3<f32>(p.x, p.y, p.z - e)).x;
    return normalize(vec3<f32>(x, y, z)); 
}

@fragment
fn fragment(
    @builtin(position) position: vec4<f32>,
    #import bevy_sprite::mesh2d_vertex_output
) -> @location(0) vec4<f32> {
    let v = vec2<f32>(view.width, view.height);
    let uv = (position.xy - v / 2.0) / view.width * 2.0;

    // World Config
    // let focal_len = 4.0;
    // let camera_pos = vec3<f32>(0.0, -7.0, 0.0);
    // let camera_dir = normalize(vec3<f32>(0.0, 1.0, 0.0));
    // let light_pos = vec3<f32>(0.0, 0.0, 10.0);
    let light_dir = normalize(vec3<f32>(-1.0, -1.0, -1.0));

    // Calculate ray position
    let to_center = camera_dir * focal_len;
    let world_up = vec3<f32>(0.0, 0.0, -1.0);
    let right = normalize(cross(to_center, world_up));
    let up = normalize(cross(right, to_center));
    let position = uv.y * up + uv.x * right + to_center;
    let ray_dir = normalize(position);
    // let pixel_pos = camera_pos + position;



    // Raymarch
    var rp = camera_pos;
    var total = 0.0;
    var color = vec4<f32>(0.0, 0.0, 0.0, 1.0);
    var hits = 0.0;
    var iters = 0u;
    loop {
        let res = mandlebulb(rp);
        let d = res.x;
        
        // Ray Hit!
        if d < epsilon {
            let ray_iters = res.y;
            let normal = calc_normal(rp);
            
            let amt_a = clamp(dot(normal * 0.8 + 0.0, -light_dir), 0.0, 1.0);
            let amt_b = clamp(ray_iters / 16.0, 0.0, 1.0);

            let mixed = color_a * amt_a * 0.5 + color_b * amt_b * 0.5;

            color = vec4<f32>(clamp(mixed.r, 0.0, 1.0), clamp(mixed.g, 0.0, 1.0), clamp(mixed.b, 0.0, 1.0), 1.0);
            break;
        }

        rp = rp + ray_dir * d;
        total = total + d;

        // Exit loop if we've exceeded the maximum number of iterations
        if total > 250.0 || iters > 100u {
            break;
        }
        hits += 0.003;
        iters += 1u;
    }
    hits = max(0.0, hits - 0.02);
    color.b += hits;
    color.r += hits * 0.15;
    // Outline effect
    // color += hits * vec4<f32>(0.6, 0.2, 1.0, 1.0);

    return color;
}