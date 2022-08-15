#import bevy_pbr::mesh_view_bindings


@group(1) @binding(0)
var<uniform> camera_pos: vec3<f32>;
@group(1) @binding(1)
var<uniform> camera_dir: vec3<f32>;
@group(1) @binding(2)
var<uniform> focal_len: f32;


// fn zfunc(c: vec2<f32>, n: u32) -> vec2<f32> {
//     var v = vec2<f32>(0.0, 0.0);
//     var i = 0u;
//     loop {
//         // Square v
//         // (a + ib)**2 = (a**2 - b**2) + 2abi
//         v = vec2<f32>(v.x * v.x - v.y * v.y, 2.0 * v.x * v.y);

//         // add c
//         v += c;

//         // increment loop counter and break
//         i = i + 1u;
//         if i == n {
//             break;
//         }
//     }
//     return v;
// }


fn sphere_dist(p: vec3<f32>, c: vec3<f32>, r: f32) -> f32 {
    return length(p - c) - r;
}

fn scene_dist(p: vec3<f32>) -> f32 {
    let d1 = sphere_dist(p, vec3<f32>(1.5, 0.0, 0.0), 3.0);
    let d2 = sphere_dist(p, vec3<f32>(-1.5, 1.0, 1.0), 2.0);
    let d3 = sphere_dist(p, vec3<f32>(3.0, -3.0, -0.5), 1.2);
    return min(d1, min(d2, d3));
}


@fragment
fn fragment(
    @builtin(position) position: vec4<f32>,
    #import bevy_sprite::mesh2d_vertex_output
) -> @location(0) vec4<f32> {
    let v = vec2<f32>(view.width, view.height);
    let uv = (position.xy - v / 2.0) / view.width * 2.0;

    // Calculate ray position
    let focal_len = 0.6;
    let camera_pos = vec3<f32>(0.0, -8.0, 2.0);
    let camera_dir = normalize(vec3<f32>(0.0, 1.0, -0.2));
    let to_center = camera_dir * focal_len;
    let world_up = vec3<f32>(0.0, 0.0, -1.0);
    let right = normalize(cross(to_center, world_up));
    let up = normalize(cross(right, to_center));
    let position = uv.y * up + uv.x * right + to_center;
    let ray_dir = normalize(position);
    let pixel_pos = camera_pos + position;



    // Raymarch
    var rp = pixel_pos;
    var total = 0.0;
    var color = vec4<f32>(0.0, 0.0, 0.0, 1.0);
    var hits = 0.0;
    loop {
        var d = scene_dist(rp);
        if d < 0.01 {
            color = vec4<f32>(pow((100.0 - total) * 0.007, 5.0), 0.0, 0.0, 1.0);
            break;
        }
        rp = rp + ray_dir * d;
        total = total + d;
        if total > 100.0 {
            break;
        }
        hits += 0.01;
    }

    // Outline effect
    hits = max(0.0, hits - 0.15);
    color += hits * vec4<f32>(0.6, 0.2, 1.0, 1.0);

    return color;
}