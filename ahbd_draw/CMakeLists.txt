# This file is automatically generated from cmake.toml - DO NOT EDIT
# See https://github.com/build-cpp/cmkr for more information

cmake_minimum_required(VERSION 3.15)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
	message(FATAL_ERROR "In-tree builds are not supported. Run CMake from a separate directory: cmake -B build")
endif()

set(CMKR_ROOT_PROJECT OFF)
if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
	set(CMKR_ROOT_PROJECT ON)

	# Bootstrap cmkr and automatically regenerate CMakeLists.txt
	include(cmkr.cmake OPTIONAL RESULT_VARIABLE CMKR_INCLUDE_RESULT)
	if(CMKR_INCLUDE_RESULT)
		cmkr()
	endif()

	# Enable folder support
	set_property(GLOBAL PROPERTY USE_FOLDERS ON)

	# Create a configure-time dependency on cmake.toml to improve IDE support
	configure_file(cmake.toml cmake.toml COPYONLY)
endif()

project(ahbd_draw)

# Target: imgui
set(imgui_SOURCES
	"dependencies/imgui/imgui.cpp"
	"dependencies/imgui/imgui_demo.cpp"
	"dependencies/imgui/imgui_draw.cpp"
	"dependencies/imgui/imgui_tables.cpp"
	"dependencies/imgui/imgui_widgets.cpp"
)

add_library(imgui INTERFACE)

target_sources(imgui INTERFACE ${imgui_SOURCES})
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${imgui_SOURCES})

target_include_directories(imgui INTERFACE
	"dependencies/imgui"
)

# Target: sol2
add_library(sol2 INTERFACE)

target_include_directories(sol2 INTERFACE
	"dependencies/sol2/include"
)

# Target: lua
set(lua_SOURCES
	"dependencies/lua/lapi.c"
	"dependencies/lua/lauxlib.c"
	"dependencies/lua/lbaselib.c"
	"dependencies/lua/lcode.c"
	"dependencies/lua/lcorolib.c"
	"dependencies/lua/lctype.c"
	"dependencies/lua/ldblib.c"
	"dependencies/lua/ldebug.c"
	"dependencies/lua/ldo.c"
	"dependencies/lua/ldump.c"
	"dependencies/lua/lfunc.c"
	"dependencies/lua/lgc.c"
	"dependencies/lua/linit.c"
	"dependencies/lua/liolib.c"
	"dependencies/lua/llex.c"
	"dependencies/lua/lmathlib.c"
	"dependencies/lua/lmem.c"
	"dependencies/lua/loadlib.c"
	"dependencies/lua/lobject.c"
	"dependencies/lua/lopcodes.c"
	"dependencies/lua/loslib.c"
	"dependencies/lua/lparser.c"
	"dependencies/lua/lstate.c"
	"dependencies/lua/lstring.c"
	"dependencies/lua/lstrlib.c"
	"dependencies/lua/ltable.c"
	"dependencies/lua/ltablib.c"
	"dependencies/lua/ltm.c"
	"dependencies/lua/lua.c"
	"dependencies/lua/luac.c"
	"dependencies/lua/lundump.c"
	"dependencies/lua/lutf8lib.c"
	"dependencies/lua/lvm.c"
	"dependencies/lua/lzio.c"
	cmake.toml
)

add_library(lua STATIC)

target_sources(lua PRIVATE ${lua_SOURCES})
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${lua_SOURCES})

target_include_directories(lua PUBLIC
	"dependencies/lua"
)

# Target: glm
set(glm_SOURCES
	"dependencies/glm/glm/detail/glm.cpp"
)

add_library(glm INTERFACE)

target_sources(glm INTERFACE ${glm_SOURCES})
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${glm_SOURCES})

target_include_directories(glm INTERFACE
	"dependencies/glm"
)

# Target: ahdb_draw
set(ahdb_draw_SOURCES
	"src/Plugin.cpp"
	"src/draw.cpp"
	"src/imgui/imgui_impl_dx11.cpp"
	"src/imgui/imgui_impl_dx12.cpp"
	"src/imgui/imgui_impl_win32.cpp"
	"src/rendering/d3d11.cpp"
	"src/rendering/d3d12.cpp"
	"src/util.cpp"
	"src/reframework/API.hpp"
	"src/reframework/Math.hpp"
	"src/rendering/d3d11.hpp"
	"src/rendering/d3d12.hpp"
	"src/rendering/shared.hpp"
	"src/Plugin.h"
	"src/draw.h"
	"src/imgui/imgui_impl_dx11.h"
	"src/imgui/imgui_impl_dx12.h"
	"src/imgui/imgui_impl_win32.h"
	"src/reframework/API.h"
	"src/util.h"
	cmake.toml
)

add_library(ahdb_draw SHARED)

target_sources(ahdb_draw PRIVATE ${ahdb_draw_SOURCES})
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${ahdb_draw_SOURCES})

target_compile_features(ahdb_draw PUBLIC
	cxx_std_20
)

target_link_libraries(ahdb_draw PUBLIC
	lua
	sol2
	imgui
	glm
	d3d11
	d3d12
	d3dcompiler
	dxgi
)

set(CMKR_TARGET ahdb_draw)
set_target_properties(ahdb_draw PROPERTIES
                      RUNTIME_OUTPUT_DIRECTORY_RELEASE ../bin
)
