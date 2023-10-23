#pragma once

#include "imgui.h"
#include "reframework/Math.hpp"

#include <optional>
#include <vector>


namespace cyl {

	enum class type {
		cylinder,
		ring
	};

	using bases = std::optional <std::tuple<std::vector<ImVec2>, std::vector<ImVec2>>>;
}

namespace cap {

	struct body {
		std::vector<ImVec2> corners;
		float angle;
		Vector2f top_circle_start;
		float top_radius;
		Vector2f bottom_circle_start;
		float bottom_radius;
	};
}

namespace draw {

	void capsule_quad(const Vector3f& start, const Vector3f& end, float radius, ImU32 color, bool outline, ImU32 color_outline);
	void capsule_ellipse(const Vector3f& start, const Vector3f& end, float radius, ImU32 color, bool outline, ImU32 color_outline);
	void sphere(const Vector3f& center, float radius, ImU32 color, bool outline, ImU32 color_outline);
	void cylinder(const Vector3f& start, const Vector3f& end, float radius, ImU32 color, bool outline, ImU32 color_outline);
	void ring(const Vector3f& start, const Vector3f& end, float radius_a, float radius_b, ImU32 color, bool outline, ImU32 color_outline);
	void box(const Vector3f& pos, const Vector3f& extent, const Matrix4x4f& rot, ImU32 color, bool outline, ImU32 color_outline);
	void box(const Vector3f& pos, const Vector3f& extent, const Vector3f& rot, ImU32 color, bool outline, ImU32 color_outline);
	void triangle(const Vector3f& pos, const Vector3f& extent, const Matrix4x4f& rot, ImU32 color, bool outline, ImU32 color_outline);
	void triangle(const Vector3f& pos, const Vector3f& extent, const Vector3f& rot, ImU32 color, bool outline, ImU32 color_outline);
}
