#pragma once

#include <reframework/API.hpp>
#include <reframework/Math.hpp>

#include <optional>
#include <vector>

namespace util {

	reframework::API::ManagedObject* get_primary_camera();
	reframework::API::ManagedObject* get_main_view();
	reframework::API::ManagedObject* get_current_scene();
	std::optional<Vector2f> world_to_screen(const Vector3f& world_pos);
	Vector4f get_transform_position(reframework::API::ManagedObject* transform);
    glm::quat get_joint_rotation(reframework::API::ManagedObject* joint);
    std::optional<Vector3f> get_camera_up();
	bool update_camera();

}

struct camera {
	std::optional<Vector3f> up{};
	Vector4f origin{};
	Vector4f forward{};
	Matrix4x4f proj{};
	Matrix4x4f view{};
	float screen_size[2];
};
