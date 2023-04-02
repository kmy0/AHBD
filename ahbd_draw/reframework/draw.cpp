#include <reframework/util.h>
#include <reframework/draw.h>


camera extern g_camera;


void _fill_and_stroke(ImU32 fill_color, ImU32 stroke_color) {
    const auto dl = ImGui::GetBackgroundDrawList();
    dl->AddConvexPolyFilled(dl->_Path.Data, dl->_Path.Size, fill_color);
    dl->AddPolyline(dl->_Path.Data, dl->_Path.Size, stroke_color, true, 1);
    dl->PathClear();
}

std::optional<cap::body> _get_capsule_body(const Vector3f& start, const Vector3f& end, float radius) {

    auto get_screen_radius = [&](const Vector3f& pos, float radius) -> std::optional<std::tuple<float, Vector2f>> {

        const auto screen_pos_center = util::world_to_screen(pos);

        if (screen_pos_center) {
            const auto pos_top = pos + (glm::normalize(*g_camera.up) * radius);
            const auto screen_pos_top = util::world_to_screen(pos_top);

            if (screen_pos_top) {
                const auto radius2d = glm::length(*screen_pos_top - *screen_pos_center);

                return std::make_tuple(radius2d, *screen_pos_center);
            }
        }

        return std::nullopt;
    };

    const auto top_screen_radius = get_screen_radius(start, radius);
    const auto bottom_screen_radius = get_screen_radius(end, radius);

    if (top_screen_radius && bottom_screen_radius) {
        const auto top_radius = std::get<0>(*top_screen_radius);
        const auto bottom_radius = std::get<0>(*bottom_screen_radius);
        const auto top_circle_start = std::get<1>(*top_screen_radius);
        const auto bottom_circle_start = std::get<1>(*bottom_screen_radius);

        if (top_screen_radius && bottom_screen_radius) {
            std::vector<Vector2f> corners(4);
            const auto delta = glm::normalize(bottom_circle_start - top_circle_start);
            const auto angle = glm::atan(delta.y, delta.x) + glm::radians(90.0f);

            corners[0] = {
                top_circle_start.x + (top_radius * std::cos(angle)),
                top_circle_start.y + (top_radius * std::sin(angle))
            };
            corners[1] = {
                top_circle_start.x + (top_radius * std::cos(angle + glm::radians(180.0f))),
                top_circle_start.y + (top_radius * std::sin(angle + glm::radians(180.0f)))
            };
            corners[2] = {
                bottom_circle_start.x + (bottom_radius * std::cos(angle + glm::radians(180.0f))),
                bottom_circle_start.y + (bottom_radius * std::sin(angle + glm::radians(180.0f)))
            };
            corners[3] = {
                bottom_circle_start.x + (bottom_radius * std::cos(angle)),
                bottom_circle_start.y + (bottom_radius * std::sin(angle))
            };

            return cap::body{
                corners,
                angle - glm::radians(90.0f),
                top_circle_start,
                top_radius,
                bottom_circle_start,
                bottom_radius
            };
        }
    }

    return std::nullopt;
};

cyl::bases _cylinder(
                const Vector3f& start_pos, const Vector3f& end_pos, float radius,
                ImU32 color, bool outline, ImU32 color_outline, 
                cyl::type type, float rot = 0.0f) {

    const auto dir = glm::normalize(end_pos - start_pos);
    auto up = glm::cross(dir, Vector3f(0, 1, 0));

    if (glm::length(up) < 0.0001f) {
        up = glm::cross(dir, Vector3f(1, 0, 0));
    }

    auto right = glm::cross(up, dir);
    up = glm::normalize(up) * radius;
    right = glm::normalize(right) * radius;

    auto get_bases = [&](const Vector3f& pos, int num_segments) -> std::optional<std::vector<Vector2f>> {
        std::vector<Vector2f> points;
        const float angle_increment = glm::radians(360.0f) / num_segments;

        for (int i = 0; i <= num_segments; i++) {

            float angle = rot + angle_increment * i;
            auto cos = right * std::cos(angle);
            auto sin = up * std::sin(angle);
            auto point = util::world_to_screen(pos + cos + sin);

            if (!point) {
                return std::nullopt;
            }

            points.push_back(*point);
        }

        return points;
    };

    auto points = get_bases(start_pos, 32);

    if (!points) {
        return std::nullopt;
    }

    const auto top_points = *points;
    points = get_bases(end_pos, 32);

    if (!points) {
        return std::nullopt;
    }

    const auto bottom_points = *points;
    const auto size = top_points.size() - 1;

    // body
    for (int i = 0; i < size; i += 1) {
        ImGui::GetBackgroundDrawList()->AddQuadFilled(
            *(ImVec2*)&top_points[i],
            *(ImVec2*)&top_points[i + 1],
            *(ImVec2*)&bottom_points[i + 1],
            *(ImVec2*)&bottom_points[i],
            color
        );
    }

    // bases
    if (type == cyl::type::cylinder) {
        for (int i = 0; i < size / 2; i += 1) {
            ImGui::GetBackgroundDrawList()->AddQuadFilled(
                *(ImVec2*)&top_points[i],
                *(ImVec2*)&top_points[i + 1],
                *(ImVec2*)&top_points[size - i - 1],
                *(ImVec2*)&top_points[size - i],
                color
            );

            ImGui::GetBackgroundDrawList()->AddQuadFilled(
                *(ImVec2*)&bottom_points[i],
                *(ImVec2*)&bottom_points[i + 1],
                *(ImVec2*)&bottom_points[size - i - 1],
                *(ImVec2*)&bottom_points[size - i],
                color
            );
        }
    }

    // bases outline 
    if (outline) {
        for (int i = 0; i < size; i += 1) {
            ImGui::GetBackgroundDrawList()->AddLine(
                *(ImVec2*)&top_points[i],
                *(ImVec2*)&top_points[i + 1],
                color_outline
            );

            ImGui::GetBackgroundDrawList()->AddLine(
                *(ImVec2*)&bottom_points[i],
                *(ImVec2*)&bottom_points[i + 1],
                color_outline
            );
        }
    }

    return std::make_tuple(top_points, bottom_points);
}

void draw::cylinder(const Vector3f& start, const Vector3f& end, float radius, ImU32 color, bool outline, ImU32 color_outline) {
    if (glm::length(end - start) <= 0.0f) {
        sphere(start, radius, color, outline, color_outline);

        return;
    }

    _cylinder(start, end, radius, color, outline, color_outline, cyl::type::cylinder);
}

void draw::ring(const Vector3f& start, const Vector3f& end, float radius_a, float radius_b, ImU32 color, bool outline, ImU32 color_outline) {
    radius_b = radius_b - radius_a;
    const auto outer_cylinder = _cylinder(start, end, radius_a, color, outline, color_outline, cyl::type::ring);

    if (!outer_cylinder) {
        return;
    }

    const auto inner_cylinder = _cylinder(start, end, radius_b, color, outline, color_outline, cyl::type::ring, glm::radians(180.0f));

    if (!inner_cylinder) {
        return;
    }

    const auto outer_top = std::get<0>(*outer_cylinder);
    const auto outer_bottom = std::get<1>(*outer_cylinder);
    const auto inner_top = std::get<0>(*inner_cylinder);
    const auto inner_bottom = std::get<1>(*inner_cylinder);
    const auto size = outer_top.size() - 1;

    for (int i = 0; i < size; i += 1) {
        ImGui::GetBackgroundDrawList()->AddQuadFilled(
            *(ImVec2*)&outer_top[i],
            *(ImVec2*)&outer_top[i + 1],
            *(ImVec2*)&inner_top[i + 1],
            *(ImVec2*)&inner_top[i],
            color
        );

        ImGui::GetBackgroundDrawList()->AddQuadFilled(
            *(ImVec2*)&outer_bottom[i],
            *(ImVec2*)&outer_bottom[i + 1],
            *(ImVec2*)&inner_bottom[i + 1],
            *(ImVec2*)&inner_bottom[i],
            color
        );
    }
}

void draw::box(const Vector3f& pos, const Vector3f& extent, ImU32 color, bool outline, ImU32 color_outline) {
    const auto min = pos - extent;
    const auto max = pos + extent;
    std::vector<ImVec2> corners(8);

    std::vector<Vector3f> corners3f = {
        Vector3f(min.x, min.y, min.z),
        Vector3f(max.x, min.y, min.z),
        Vector3f(max.x, max.y, min.z),
        Vector3f(min.x, max.y, min.z),
        Vector3f(min.x, max.y, max.z),
        Vector3f(min.x, min.y, max.z),
        Vector3f(max.x, min.y, max.z),
        Vector3f(max.x, max.y, max.z)
    };

    for (int i = 0; i <= 7; i++) {
        auto corner = util::world_to_screen(corners3f[i]);

        if (!corner) {
            return;
        }

        corners[i] = *(ImVec2*)&*corner;
    }

    std::vector<std::vector<ImVec2>> quads = {
        {corners[0], corners[1], corners[2], corners[3]},
        {corners[0], corners[3], corners[4], corners[5]},
        {corners[0], corners[1], corners[6], corners[5]},
        {corners[1], corners[2], corners[7], corners[6]},
        {corners[2], corners[3], corners[4], corners[7]}, 
        {corners[4], corners[5], corners[6], corners[7]} 
    };

    for (auto quad : quads) {
        ImGui::GetBackgroundDrawList()->PathLineTo(quad[0]);
        ImGui::GetBackgroundDrawList()->PathLineTo(quad[1]);
        ImGui::GetBackgroundDrawList()->PathLineTo(quad[2]);
        ImGui::GetBackgroundDrawList()->PathLineTo(quad[3]);

        if (outline) {
            _fill_and_stroke(color, color_outline);
        }
        else {
            ImGui::GetBackgroundDrawList()->PathFillConvex(color);
        }
    }
}

void draw::sphere(const Vector3f& center, float radius, ImU32 color, bool outline, ImU32 color_outline) {
    if (!g_camera.up) {
        return;
    }

    const auto screen_pos_center = util::world_to_screen(center);

    if (screen_pos_center) {
        const auto pos_top = center + (glm::normalize(*g_camera.up) * radius);
        const auto screen_pos_top = util::world_to_screen(pos_top);

        if (screen_pos_top) {
            const auto radius2d = glm::length(*screen_pos_top - *screen_pos_center);

            // Inner
            ImGui::GetBackgroundDrawList()->AddCircleFilled(
                *(ImVec2*)&*screen_pos_center,
                radius2d,
                color,
                32
            );

            // Outline
            if (outline) {
                ImGui::GetBackgroundDrawList()->AddCircle(
                    *(ImVec2*)&*screen_pos_center,
                    radius2d,
                    color_outline,
                    32
                );
            }
        }
    }
}

void draw::capsule_ellipse(const Vector3f& start, const Vector3f& end, float radius, ImU32 color, bool outline, ImU32 color_outline) {
    if (!g_camera.up) {
        return;
    }

    if (glm::length(end - start) <= 0.0f) {
        sphere(start, radius, color, outline, color_outline);

        return;
    }

    auto opt = _get_capsule_body(start, end, radius);

    if (opt) {
        auto body = *opt;

        auto get_ellipse = [&](const Vector3f normal, const Vector2f start, float radius, float a_min, float a_max) {

            auto elliptical_arc_to = [&](const Vector2f& center, float radius_x, float radius_y, float rot, float a_min, float a_max, int num_segments) -> std::vector<Vector2f> {
                const float cos_rot = std::cos(rot);
                const float sin_rot = std::sin(rot);
                std::vector<Vector2f> points;

                for (int i = 0; i <= num_segments; i++) {
                    const float a = a_min + ((float)i / (float)num_segments) * (a_max - a_min);
                    Vector2f point(center.x + std::cos(a) * radius_x, center.y + std::sin(a) * radius_y);
                    point.x -= center.x;
                    point.y -= center.y;
                    const float rel_x = (point.x * cos_rot) - (point.y * sin_rot);
                    const float rel_y = (point.x * sin_rot) + (point.y * cos_rot);
                    point.x = rel_x + center.x;
                    point.y = rel_y + center.y;
                    points.push_back(point);
                }

                return points;
            };

            const float cam_angle = std::acos(glm::dot(normal, Vector3f(g_camera.forward)));
            const float minor_radius = radius * std::cos(cam_angle);
            return elliptical_arc_to(start, radius, minor_radius, body.angle + glm::radians(90.0f), glm::radians(a_min), glm::radians(a_max), 32);
        };

        const auto top_points = get_ellipse(glm::normalize(start - end), body.top_circle_start, body.top_radius, 0.0f, 360.0f);
        const auto bottom_points = get_ellipse(glm::normalize(end - start), body.bottom_circle_start, body.bottom_radius, 360.0f, 0.0f);
        const auto size = top_points.size() - 1;

        // body
        for (int i = 0; i < size; i += 1) {
            ImGui::GetBackgroundDrawList()->AddQuadFilled(
                *(ImVec2*)&top_points[i],
                *(ImVec2*)&top_points[i + 1],
                *(ImVec2*)&bottom_points[i + 1],
                *(ImVec2*)&bottom_points[i],
                color
            );
        }

        // bases outline
        if (outline) {
            for (int i = 0; i < size; i += 1) {
                ImGui::GetBackgroundDrawList()->AddLine(
                    *(ImVec2*)&top_points[i],
                    *(ImVec2*)&top_points[i + 1],
                    color_outline
                );

                ImGui::GetBackgroundDrawList()->AddLine(
                    *(ImVec2*)&bottom_points[i],
                    *(ImVec2*)&bottom_points[i + 1],
                    color_outline
                );
            }
        }

        // caps
        const auto length = glm::length(body.bottom_circle_start - body.top_circle_start);
        const auto top_radius_ratio = glm::clamp(body.top_radius / length, -1.0f, 1.0f);
        const auto bottom_radius_ratio = glm::clamp(body.bottom_radius / length, -1.0f, 1.0f);

        const auto top_cos_angle = std::acos(top_radius_ratio);
        const auto top_sin_angle = std::asin(top_radius_ratio);
        const auto top_start_angle = body.angle - top_cos_angle - top_sin_angle + glm::radians(180.0f);
        const auto top_end_angle = body.angle + top_cos_angle + top_sin_angle + glm::radians(180.0f);

        const auto bottom_cos_angle = std::acos(bottom_radius_ratio);
        const auto bottom_sin_angle = std::asin(bottom_radius_ratio);
        const auto bottom_start_angle = body.angle - bottom_cos_angle - bottom_sin_angle;
        const auto bottom_end_angle = body.angle + bottom_cos_angle + bottom_sin_angle;

        ImGui::GetBackgroundDrawList()->PathArcTo(
            *(ImVec2*)&body.top_circle_start, body.top_radius, top_start_angle, top_end_angle, 32
        );
        ImGui::GetBackgroundDrawList()->PathArcTo(
            *(ImVec2*)&body.bottom_circle_start, body.bottom_radius, bottom_start_angle, bottom_end_angle, 32
        );

        if (outline) {
            _fill_and_stroke(color, color_outline);
        }
        else {
            ImGui::GetBackgroundDrawList()->PathFillConvex(color);
        }
    }
}

void draw::capsule_quad(const Vector3f& start, const Vector3f& end, float radius, ImU32 color, bool outline, ImU32 color_outline) {
    if (!g_camera.up) {
        return;
    }

    if (glm::length(end - start) <= 0.0f) {
        sphere(start, radius, color, outline, color_outline);

        return;
    }

    auto opt = _get_capsule_body(start, end, radius);

    if (opt) {
        auto body = *opt;

        sphere(start, radius, color, outline, color_outline);
        sphere(end, radius, color, outline, color_outline);

        // Draw a quad
        ImGui::GetBackgroundDrawList()->AddQuadFilled(
            *(ImVec2*)&body.corners[0],
            *(ImVec2*)&body.corners[1],
            *(ImVec2*)&body.corners[2],
            *(ImVec2*)&body.corners[3],
            color
        );

        if (outline) {
            ImGui::GetBackgroundDrawList()->AddLine(
                *(ImVec2*)&body.corners[0],
                *(ImVec2*)&body.corners[3],
                color_outline
            );

            ImGui::GetBackgroundDrawList()->AddLine(
                *(ImVec2*)&body.corners[1],
                *(ImVec2*)&body.corners[2],
                color_outline
            );
        }
    }
}
