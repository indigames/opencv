# [IGE]: Add Android native camera
    if(ANDROID AND ANDROID_NATIVE_API_LEVEL GREATER 20)
        set(HAVE_ANDROID_NATIVE_CAMERA TRUE)
        set(libs "-landroid -llog")
        ocv_add_external_target(android_native_camera "" "${libs}" "HAVE_ANDROID_NATIVE_CAMERA")
    endif()
    set(HAVE_ANDROID_NATIVE_CAMERA ${HAVE_ANDROID_NATIVE_CAMERA} PARENT_SCOPE)
# [/IGE]

