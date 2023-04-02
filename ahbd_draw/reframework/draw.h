#pragma once

#include <imgui/imgui.h>
#include <reframework/Math.hpp>

#include <optional>
#include <vector>


namespace cyl {

	enum class type {
		cylinder,
		ring
	};

	using bases = std::optional <std::tuple<std::vector<Vector2f>, std::vector<Vector2f>>>;
}

namespace cap {

	struct body {
		std::vector<Vector2f> corners;
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
	void box(const Vector3f& pos, const Vector3f& extent, ImU32 color, bool outline, ImU32 color_outline);
}
