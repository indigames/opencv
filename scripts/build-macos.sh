#!/bin/bash 

export LIB_NAME=OpenCV

export CURR_DIR=$PWD

# WORKSPACE was set by default in Jenkins
if [ -z ${WORKSPACE+x} ]; 
then 
    echo "WORKSPACE is unset"; # which mean we run on local machine, not Jenkins
    SCRIPT_PATH=$(greadlink -f "$0"); # installed with 'brew install coreutils'
    SCRIPT_DIR=$(dirname "$SCRIPT_PATH");
    export WORKSPACE=$SCRIPT_DIR/..;
fi

export PROJECT_DIR=$WORKSPACE
export NCORES=$(sysctl -n hw.ncpu)
export PATH="$PATH:/usr/local/bin"

# IGE_LIBS evironment variable, eg. 'echo export IGE_LIBS=/Volumes/Projects/igeEngine/igeLibs > ~/.bash_profile'
# export IGE_LIBS=$PROJECT_DIR/../igeLibs

export BUILD_DIR=$PROJECT_DIR/build/macos
export OUTPUT_DIR=$PROJECT_DIR/igeLibs/$LIB_NAME/libs/macos
echo $IGE_LIBS
if [ ! -d "$PROJECT_DIR/igeLibs" ]; then
    ln -s "$IGE_LIBS" "$PROJECT_DIR/igeLibs"
fi

[ ! -d "$BUILD_DIR" ] && mkdir -p $BUILD_DIR
cd $BUILD_DIR
cmake $PROJECT_DIR -G Xcode -DOSX=1
cmake --build . --config Release -- -jobs $NCORES
if [ $? -ne 0 ]; then
  echo "Error: CMAKE compile failed!"
  exit $?
fi

[ ! -d "$OUTPUT_DIR/x64" ] && mkdir -p $OUTPUT_DIR/x64
cp -R -f -p ./lib/Release/*.a $OUTPUT_DIR/x64
cp -R -f -p ./3rdparty/lib/Release/*.a $OUTPUT_DIR/x64
cp -R -f -p ./Release/*.so $OUTPUT_DIR/x64

echo DONE!
cd $CURR_DIR
