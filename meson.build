project (
    'physv', [ 'vala', 'c' ],
    version: '1.0.0',
    default_options: [
        'buildtype=release',
    ],
)

# Variables
source_dir = meson.current_source_dir ()
vapi_dir = source_dir / 'vapi'
operating_system = build_machine.system ()

# Build variables
project_source = []
project_dependencies = []
project_include = []

# Compilers
valac = meson.get_compiler ('vala')
cc = meson.get_compiler ('c')

# Compiler arguments
valac_arguments = [
    '--vapidir=' + vapi_dir
]

cc_arguments = [ ]

add_project_arguments (valac_arguments, language: 'vala')
add_project_arguments (cc_arguments, language: 'c')

project_source = files (
    'src/Debug/Block.vala',

    'src/Vector2.vala',
    'src/Transform.vala',
    'src/Colour.vala',
    'src/Collision.vala',
    'src/AABB.vala',
    'src/Manifold.vala',

    'src/PhysicsBody.vala',
    'src/PhysicsWorld.vala',

    'src/Main.vala',
)

project_dependencies = [
    dependency ('glib-2.0'),
    dependency ('gobject-2.0'),

    valac.find_library ('raylib', dirs: vapi_dir),

    cc.find_library ('m'),
    cc.find_library ('raylib')
]

project_lib = executable (
    meson.project_name (),

    project_source,

    dependencies: [
        project_dependencies
    ],

    # vala_header: 'physv.h',
    # vala_vapi: 'physv.vapi',
)
