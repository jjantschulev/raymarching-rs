use bevy::{
    asset::AssetServerSettings,
    prelude::{shape::Quad, *},
    reflect::TypeUuid,
    render::render_resource::{AsBindGroup, Extent3d, ShaderRef},
    sprite::{Material2d, Material2dPlugin, MaterialMesh2dBundle},
};

struct ShaderHandle(Handle<PostProcessingMaterial>);

fn main() {
    App::new()
        .insert_resource(AssetServerSettings {
            watch_for_changes: cfg!(debug_assertions),
            ..Default::default()
        })
        .insert_resource(WindowDescriptor {
            width: 1200.0,
            height: 1200.0,
            ..Default::default()
        })
        .add_plugins(DefaultPlugins)
        .add_plugin(Material2dPlugin::<PostProcessingMaterial>::default())
        .add_startup_system(setup)
        .add_system(bevy::window::close_on_esc)
        .add_system(move_around)
        .run();
}

// fn update_tex_size(mut meshes: ResMut<Assets<Mesh>>, mut windows: ResMut<Windows>) {
//     let window = windows.get_primary_mut().unwrap();
//     let size = Extent3d {
//         width: window.physical_width(),
//         height: window.physical_height(),
//         ..default()
//     };
//     meshes.get_mut(handle)
// }

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut post_processing_materials: ResMut<Assets<PostProcessingMaterial>>,
    mut windows: ResMut<Windows>,
) {
    // Get window size
    let window = windows.get_primary_mut().unwrap();

    let width = 1800.0;
    let height = 1800.0;
    let window_width = window.physical_width() as f32;
    let window_height = window.physical_height() as f32;

    // Create material
    let material_handle = post_processing_materials.add(PostProcessingMaterial {
        pos: Vec3::new(0.0, -10.0, 0.0),
        dir: Vec3::Y,
        focal_len: 1.0,
        power: 10.0,
    });
    commands.insert_resource(ShaderHandle(material_handle.clone()));

    // Create a Quad
    let mesh = meshes.add(Mesh::from(Quad::new(Vec2::new(width, height))));

    commands.spawn_bundle(MaterialMesh2dBundle {
        mesh: mesh.into(),
        material: material_handle,
        transform: Transform {
            translation: Vec3::new(0.0, 0.0, 1.0),
            scale: Vec3::new(window_width / width, window_height / height, 1.0),
            ..default()
        },
        ..default()
    });

    // Create a 2D Camera
    commands.spawn_bundle(Camera2dBundle::default());
}

fn move_around(
    mut post_processing_materials: ResMut<Assets<PostProcessingMaterial>>,
    handle: Res<ShaderHandle>,
    input: Res<Input<KeyCode>>,
    time: Res<Time>,
) {
    const SPEED: f32 = 1.0;
    const TURN_SPEED: f32 = 1.0;
    const FOCAL_ZOOM: f32 = 0.5;
    const POWER_SPEED: f32 = 1.0;
    let mut material = post_processing_materials.get_mut(&handle.0).unwrap();
    let dt = time.delta_seconds();

    // Change power
    if input.pressed(KeyCode::Home) {
        material.power += POWER_SPEED * dt;
    }
    if input.pressed(KeyCode::End) {
        material.power -= POWER_SPEED * dt;
    }

    // Move camera
    if input.pressed(KeyCode::W) {
        material.pos.y += SPEED * dt;
    }
    if input.pressed(KeyCode::S) {
        material.pos.y -= SPEED * dt;
    }
    if input.pressed(KeyCode::A) {
        material.pos.x += SPEED * dt;
    }
    if input.pressed(KeyCode::D) {
        material.pos.x -= SPEED * dt;
    }
    if input.pressed(KeyCode::R) {
        material.pos.z += SPEED * dt;
    }
    if input.pressed(KeyCode::F) {
        material.pos.z -= SPEED * dt;
    }

    // Change camera zoom
    if input.pressed(KeyCode::PageUp) {
        material.focal_len += FOCAL_ZOOM * dt;
    }
    if input.pressed(KeyCode::PageDown) {
        material.focal_len -= FOCAL_ZOOM * dt;
    }

    // Look around
    let mut theta = material.dir.z.acos();
    let mut phi = (material.dir.y / theta.sin()).asin();

    if input.pressed(KeyCode::Left) {
        phi += TURN_SPEED * dt;
    }
    if input.pressed(KeyCode::Right) {
        phi -= TURN_SPEED * dt;
    }
    if input.pressed(KeyCode::Up) {
        theta += TURN_SPEED * dt;
    }
    if input.pressed(KeyCode::Down) {
        theta -= TURN_SPEED * dt;
    }

    material.dir.x = theta.sin() * phi.cos();
    material.dir.y = theta.sin() * phi.sin();
    material.dir.z = theta.cos();
}

#[derive(AsBindGroup, TypeUuid, Clone)]
#[uuid = "bc2f08eb-a0fb-43f1-a908-54871ea597d5"]
struct PostProcessingMaterial {
    #[uniform(0)]
    pos: Vec3,
    #[uniform(1)]
    dir: Vec3,
    #[uniform(2)]
    focal_len: f32,
    #[uniform(3)]
    power: f32,
}

impl Material2d for PostProcessingMaterial {
    fn fragment_shader() -> ShaderRef {
        "shaders/shader.wgsl".into()
    }
}
