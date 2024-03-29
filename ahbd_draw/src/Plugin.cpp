#include "Plugin.h"
#include "draw.h"
#include "util.h"

#include <sol/sol.hpp>
#include "imgui/imgui_impl_dx11.h"
#include "imgui/imgui_impl_dx12.h"
#include "imgui/imgui_impl_win32.h"
#include "rendering/d3d11.hpp"
#include "rendering/d3d12.hpp"
#include <mutex>


using API = reframework::API;
lua_State* g_lua{};
bool g_initialized{ false };
bool g_draw{ false };
std::mutex g_mutex;


bool initialize_imgui() {
    if (g_initialized) {
        return true;
    }

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();

    const auto renderer = API::get()->param()->renderer_data;

    DXGI_SWAP_CHAIN_DESC desc{};
    const auto swapchain = static_cast<IDXGISwapChain*>(renderer->swapchain);
    swapchain->GetDesc(&desc);

    if (!ImGui_ImplWin32_Init(desc.OutputWindow)) {
        return false;
    }

    if (renderer->renderer_type == REFRAMEWORK_RENDERER_D3D11) {
        if (!g_d3d11.initialize()) {
            return false;
        }
    } else if (renderer->renderer_type == REFRAMEWORK_RENDERER_D3D12) {
        if (!g_d3d12.initialize()) {
            return false;
        }
    }

    ImGui::GetStyle().AntiAliasedFill = false;
    g_initialized = true;
    return true;
}

bool start_frame() {
    std::lock_guard _{ g_mutex };
    if (!g_initialized) {
        return false;
    }

    if (!util::update_camera()) {
        return false;
    }

    const auto renderer_data = API::get()->param()->renderer_data;

    if (renderer_data->renderer_type == REFRAMEWORK_RENDERER_D3D11) {
        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();

    }
    else if (renderer_data->renderer_type == REFRAMEWORK_RENDERER_D3D12) {
        auto command_queue = (ID3D12CommandQueue*)renderer_data->command_queue;

        if (command_queue == nullptr) {
            return false;
        }

        ImGui_ImplDX12_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();
    }
    return true;
}

void end_frame() {
    std::lock_guard _{ g_mutex };
    ImGui::EndFrame();
    g_draw = true;
}

void on_lua_state_created(lua_State* l) {
    API::LuaLock _{};
    g_lua = l;
    sol::state_view lua{ g_lua };

    auto ahbd_draw = lua.create_table();

    ahbd_draw["start_frame"] = start_frame;
    ahbd_draw["end_frame"] = end_frame;
    ahbd_draw["cylinder"] = draw::cylinder;
    ahbd_draw["ring"] = draw::ring;
    ahbd_draw["box"] = sol::overload(
        [](const Vector3f& pos, const Vector3f& extent, const Matrix4x4f& rot, ImU32 color, bool outline, ImU32 color_outline) {
            draw::box(pos, extent, rot, color, outline, color_outline);
        },
        [](const Vector3f& pos, const Vector3f& extent, const Vector3f& rot, ImU32 color, bool outline, ImU32 color_outline) {
            draw::box(pos, extent, rot, color, outline, color_outline);
        }
    );
    ahbd_draw["triangle"] = sol::overload(
        [](const Vector3f& pos, const Vector3f& extent, const Matrix4x4f& rot, ImU32 color, bool outline, ImU32 color_outline) {
            draw::triangle(pos, extent, rot, color, outline, color_outline);
        },
        [](const Vector3f& pos, const Vector3f& extent, const Vector3f& rot, ImU32 color, bool outline, ImU32 color_outline) {
            draw::triangle(pos, extent, rot, color, outline, color_outline);
        }
     );
    ahbd_draw["capsule_ellipse"] = draw::capsule_ellipse;
    ahbd_draw["capsule_quad"] = draw::capsule_quad;
    ahbd_draw["sphere"] = draw::sphere;
    lua["ahbd_draw"] = ahbd_draw;
}

void on_lua_state_destroyed(lua_State* l) {
    API::LuaLock _{};
    g_lua = nullptr;
    g_draw = false;
}

void on_device_reset() {
    const auto renderer_data = API::get()->param()->renderer_data;

    if (renderer_data->renderer_type == REFRAMEWORK_RENDERER_D3D11) {
        ImGui_ImplDX11_Shutdown();
        g_d3d11 = {};
    }

    if (renderer_data->renderer_type == REFRAMEWORK_RENDERER_D3D12) {
        ImGui_ImplDX12_Shutdown();
        g_d3d12 = {};
    }

    g_initialized = false;
    g_draw = false;
}

void on_frame() {
    std::lock_guard _{ g_mutex };
    if (!g_initialized) {
        if (!initialize_imgui()) {
            return;
        }
    }

    if (g_draw) {
        const auto renderer_data = API::get()->param()->renderer_data;

        if (renderer_data->renderer_type == REFRAMEWORK_RENDERER_D3D11) {
            ImGui::Render();
            g_d3d11.render_imgui();

        }
        else if (renderer_data->renderer_type == REFRAMEWORK_RENDERER_D3D12) {
            auto command_queue = (ID3D12CommandQueue*)renderer_data->command_queue;

            if (command_queue == nullptr) {
                return;
            }

            ImGui::Render();
            g_d3d12.render_imgui();
        }

        g_draw = false;
    }
}

extern "C" __declspec(dllexport) void reframework_plugin_required_version(REFrameworkPluginVersion * version) {
    version->major = REFRAMEWORK_PLUGIN_VERSION_MAJOR;
    version->minor = REFRAMEWORK_PLUGIN_VERSION_MINOR;
    version->patch = REFRAMEWORK_PLUGIN_VERSION_PATCH;
}

extern "C" __declspec(dllexport) bool reframework_plugin_initialize(const REFrameworkPluginInitializeParam * param) {
    API::initialize(param);
    ImGui::CreateContext();

    const auto functions = param->functions;
    functions->on_lua_state_created(on_lua_state_created);
    functions->on_lua_state_destroyed(on_lua_state_destroyed);
    functions->on_frame(on_frame);
    functions->on_device_reset(on_device_reset);

    return true;
}
