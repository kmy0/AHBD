git pull --recurse-submodules
git submodule update --init --recursive
cmake -B build
cmake --build build --config Release
pause