#include "util.h"

camera g_camera{};

reframework::API::ManagedObject *util::get_main_view() {
    const auto &api = reframework::API::get();
    static auto scene_manager_type = api->tdb()->find_type("via.SceneManager");
    static auto get_main_view_method =
        scene_manager_type->find_method("get_MainView");
    static auto main_view =
        get_main_view_method->call<reframework::API::ManagedObject *>(
            api->sdk()->functions->get_vm_context(),
            api->get_native_singleton("via.SceneManager"));

    return main_view;
}

reframework::API::ManagedObject *util::get_primary_camera() {
    const auto &api = reframework::API::get();
    const auto main_view = get_main_view();

    if (main_view == nullptr) {
        return nullptr;
    }

    static auto scene_view_type = api->tdb()->find_type("via.SceneView");
    static auto get_primary_camera_method =
        scene_view_type->find_method("get_PrimaryCamera");
    static auto camera =
        get_primary_camera_method->call<reframework::API::ManagedObject *>(
            api->sdk()->functions->get_vm_context(), main_view);

    return camera;
}

reframework::API::ManagedObject *util::get_current_scene() {
    const auto &api = reframework::API::get();

    static auto scene_manager_type = api->tdb()->find_type("via.SceneManager");
    static auto get_current_scene_method =
        scene_manager_type->find_method("get_CurrentScene");
    static auto scene =
        get_current_scene_method->call<reframework::API::ManagedObject *>(
            api->sdk()->functions->get_vm_context(),
            api->get_native_singleton("via.SceneManager"));

    return scene;
}

glm::quat util::get_joint_rotation(reframework::API::ManagedObject *joint) {
    const auto &api = reframework::API::get();
    static auto get_rotation_method =
        api->tdb()->find_type("via.Joint")->find_method("get_Rotation");

    glm::quat rotation{};
    get_rotation_method->call<reframework::API::ManagedObject *>(
        &rotation, api->sdk()->functions->get_vm_context(), joint);

    return rotation;
}

Vector4f
util::get_transform_position(reframework::API::ManagedObject *transform) {
    auto &api = reframework::API::get();
    const auto tdb = api->tdb();

    static auto transform_def = tdb->find_type("via.Transform");
    static auto get_position_method =
        transform_def->find_method("get_Position");

    Vector4f pos{};
    get_position_method->call<Vector4f *>(
        &pos, api->sdk()->functions->get_vm_context(), transform);

    return pos;
}

std::optional<Vector3f> util::get_camera_up() {
    auto camera = get_primary_camera();

    if (camera == nullptr) {
        return std::nullopt;
    }

    auto &api = reframework::API::get();
    const auto tdb = api->tdb();
    auto context = api->sdk()->functions->get_vm_context();

    static auto transform_def = tdb->find_type("via.Transform");
    static auto get_gameobject_method =
        transform_def->find_method("get_GameObject");
    static auto get_joints_method = transform_def->find_method("get_Joints");

    static auto gameobject_def = tdb->find_type("via.GameObject");
    static auto get_transform_method =
        gameobject_def->find_method("get_Transform");

    auto camera_gameobject =
        get_gameobject_method->call<reframework::API::ManagedObject *>(context,
                                                                       camera);

    if (camera_gameobject == nullptr) {
        return std::nullopt;
    }

    auto camera_transform =
        get_transform_method->call<reframework::API::ManagedObject *>(
            context, camera_gameobject);

    if (camera_transform == nullptr) {
        return std::nullopt;
    }
    auto camera_joints =
        get_joints_method->call<reframework::API::ManagedObject *>(
            context, camera_transform);

    if (camera_joints == nullptr) {
        return std::nullopt;
    }

    static auto joints_def = camera_joints->get_type_definition();
    static auto get_item_method = joints_def->find_method("get_Item");
    auto camera_joint =
        get_item_method->call<reframework::API::ManagedObject *>(
            context, camera_joints, 0);

    if (camera_joint == nullptr) {
        return std::nullopt;
    }

    return get_joint_rotation(camera_joint) * Vector3f{0.0f, 1.0f, 0.0f};
}

std::optional<Vector2f> util::world_to_screen(const Vector3f &world_pos) {
    auto camera = util::get_primary_camera();

    if (camera == nullptr) {
        return std::nullopt;
    }

    auto &api = reframework::API::get();
    auto context = api->sdk()->functions->get_vm_context();
    const auto tdb = api->tdb();

    static auto math_t = tdb->find_type("via.math");
    static auto world_to_screen = math_t->find_method(
        "worldPos2ScreenPos(via.vec3, via.mat4, via.mat4, via.Size)");

    const Vector4f pos = Vector4f{world_pos, 1.0f};
    Vector4f screen_pos{};

    const auto delta = pos - g_camera.origin;

    // behind camera
    if (glm::dot(delta, -g_camera.forward) <= 0.0f) {
        return std::nullopt;
    }

    world_to_screen->call(&screen_pos, context, &pos, &g_camera.view,
                          &g_camera.proj, &g_camera.screen_size);

    return Vector2f{screen_pos.x, screen_pos.y};
}

bool util::update_camera() {
    auto camera = util::get_primary_camera();

    if (camera == nullptr) {
        return false;
    }

    auto main_view = util::get_main_view();

    if (main_view == nullptr) {
        return false;
    }

    auto &api = reframework::API::get();
    auto context = api->sdk()->functions->get_vm_context();
    const auto tdb = api->tdb();

    static auto transform_def = tdb->find_type("via.Transform");
    static auto get_gameobject_method =
        transform_def->find_method("get_GameObject");
    static auto get_axisz_method = transform_def->find_method("get_AxisZ");

    static auto gameobject_def = tdb->find_type("via.GameObject");
    static auto get_transform_method =
        gameobject_def->find_method("get_Transform");

    auto camera_gameobject =
        get_gameobject_method->call<reframework::API::ManagedObject *>(context,
                                                                       camera);
    auto camera_transform =
        get_transform_method->call<reframework::API::ManagedObject *>(
            context, camera_gameobject);

    g_camera.origin = get_transform_position(camera_transform);
    get_axisz_method->call(&g_camera.forward, context, camera_transform);
    camera->call("get_ProjectionMatrix", &g_camera.proj, context, camera);
    camera->call("get_ViewMatrix", &g_camera.view, context, camera);
    main_view->call("get_WindowSize", &g_camera.screen_size, context,
                    main_view);
    g_camera.up = get_camera_up();

    return true;
}
