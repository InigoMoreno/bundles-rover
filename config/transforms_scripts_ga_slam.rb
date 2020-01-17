Quaternion = Eigen::Quaternion
Vector = Eigen::Vector3
PI = Math::PI

static_transform Quaternion.Identity(), Vector.Zero(),
    'left_camera_viso2' => 'left_camera_bb2'
    #'left_camera_viso2' => 'left_camera_bb3'

static_transform Quaternion.Identity(), Vector.Zero(),
    'hazcam' => 'left_camera_bb2'

static_transform Quaternion.Identity(), Vector.Zero(),
    'loccam' => 'left_camera_bb3'

static_transform \
    Quaternion.from_euler(Vector.new(
        -PI/2 - 0.004,
        0.023,
        -PI/2 - 0.544),
        2, 1, 0),
    Vector.new(
        0.527,
        0.073,
        0.058),
    'left_camera_bb2' => 'body'

static_transform \
    Quaternion.from_euler(Vector.new(
        -PI/2 - 0.006,
        0.021,
        -PI/2 - 0.296),
        2, 1, 0),
    Vector.new(
        0.426,
        0.129,
        0.491),
    'left_camera_bb3' => 'body'

