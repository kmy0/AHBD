git pull --recurse-submodules
git submodule update --init --recursive
pushd deps\hb_draw
call build.bat
popd
md bin\reframework\plugins
md bin\reframework\autorun
robocopy reframework bin\reframework /mir
robocopy deps\hb_draw\bin bin\reframework\plugins hb_draw.dll
pushd bin\reframework\plugins
ren hb_draw.dll ahdb_draw.dll
popd
tar -a -cf AHBD.zip -C bin reframework