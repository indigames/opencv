// This file is part of OpenCV project.
// It is subject to the license terms in the LICENSE file found in the top-level directory
// of this distribution and at http://opencv.org/license.html

#include "precomp.hpp"

#include <memory>
#include <condition_variable>
#include <mutex>
#include <thread>
#include <chrono>
#include <jni.h>

using namespace cv;

#define COLOR_FormatYUV420Planar 19
#define COLOR_FormatYUV420SemiPlanar 21
#define IMAGE_FORMAT_YUV_420_888 0x23
#define COLOR_FormatUnknown -1
#define COLOR_FormatYUV420Planar 19
#define COLOR_FormatYUV420SemiPlanar 21

JavaVM* jVM;
jclass g_clsActivity = nullptr;
jclass g_clsImageReader = nullptr;
jclass g_clsImage = nullptr;
jclass g_clsImagePlane = nullptr;

jfieldID fid_sInstance = nullptr;
jmethodID mid_openCamera = nullptr;
jfieldID fid_imageReader = nullptr;
jmethodID mid_acquireNextImage = nullptr;
jmethodID mid_acquireLatestImage = nullptr;
jmethodID mid_getFormat = nullptr;
jmethodID mid_close = nullptr;
jmethodID mid_getPlanes = nullptr;
jmethodID mid_getRowStride = nullptr;
jmethodID mid_getPixelStride = nullptr;
jmethodID mid_getBuffer = nullptr;

bool AndroidCameraCapture_setJavaVM(JavaVM* vm);
bool InitCameraJNI(int idx, int width, int height);

class JniEnvScope {
public:
    JniEnvScope() {
        attached = false;
        int stat = jVM->GetEnv((void **)&env, JNI_VERSION_1_6);
        if (stat == JNI_EDETACHED) {
            if (jVM->AttachCurrentThread(&env, NULL) == JNI_OK) {
                attached = true;
            }
        }
    }

    ~JniEnvScope() {
        if (attached) {
            jVM->DetachCurrentThread();
        }
    }

    JNIEnv *env;

private:
    bool attached;
};


bool AndroidCameraCapture_setJavaVM(JavaVM* vm) {
    jVM = vm;
    JNIEnv* env;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR;
    }

    g_clsActivity = reinterpret_cast<jclass>(env->NewGlobalRef(env->FindClass("org/opencv/CameraActivity")));
    g_clsImageReader = reinterpret_cast<jclass>(env->NewGlobalRef(env->FindClass("android/media/ImageReader")));
    g_clsImage = reinterpret_cast<jclass>(env->NewGlobalRef(env->FindClass("android/media/Image")));
    g_clsImagePlane = reinterpret_cast<jclass>(env->NewGlobalRef(env->FindClass("android/media/Image$Plane")));

    fid_sInstance = env->GetStaticFieldID(g_clsActivity, "sInstance", "Lorg/opencv/CameraActivity;");
    mid_openCamera = env->GetMethodID(g_clsActivity, "openCamera", "(III)V");
    fid_imageReader = env->GetFieldID(g_clsActivity, "mImageReader", "Landroid/media/ImageReader;");
    mid_acquireNextImage = env->GetMethodID(g_clsImageReader, "acquireNextImage", "()Landroid/media/Image;");
    mid_acquireLatestImage = env->GetMethodID(g_clsImageReader, "acquireLatestImage", "()Landroid/media/Image;");
    mid_getFormat = env->GetMethodID(g_clsImage, "getFormat", "()I");
    mid_close = env->GetMethodID(g_clsImage, "close", "()V");

    mid_getPlanes = env->GetMethodID(g_clsImage, "getPlanes", "()[Landroid/media/Image$Plane;");
    mid_getRowStride = env->GetMethodID(g_clsImagePlane, "getRowStride", "()I");
    mid_getPixelStride = env->GetMethodID(g_clsImagePlane, "getPixelStride", "()I");
    mid_getBuffer = env->GetMethodID(g_clsImagePlane, "getBuffer", "()Ljava/nio/ByteBuffer;");

    return true;
}

bool InitCameraJNI(int idx, int width, int height) {
    if (!jVM) {
        return false;
    }

    JniEnvScope sc;
    JNIEnv *env = sc.env;

    jobject sInstance = env->GetStaticObjectField(g_clsActivity, fid_sInstance);
    env->CallVoidMethod(sInstance, mid_openCamera, idx, width, height);
    env->DeleteLocalRef(sInstance);
    return true;
}

class AndroidCameraCapture : public IVideoCapture {
private:
    int32_t index;
    int32_t frameWidth;
    int32_t frameHeight;
    int32_t colorFormat;

    std::vector<uint8_t> buffer;
    bool _isOpened;

public:
    AndroidCameraCapture(): index(0), frameWidth(640), frameHeight(480), colorFormat(0), _isOpened(false) {}
    ~AndroidCameraCapture() { cleanUp(); }

    bool initCapture(int idx) {
        index = idx;
        return true;
    }

    void cleanUp() {
        if(_isOpened) {
            _isOpened = false;
        }
    }

    bool grabFrame() CV_OVERRIDE {
        if(!jVM || frameWidth < 0 || frameHeight < 0) {
            return false;
        }

        if(!_isOpened) {
            InitCameraJNI(index, frameWidth, frameHeight);
            _isOpened = true;
            return false;
        }

        // clear buffer
        buffer.clear();

        JniEnvScope sc;
        JNIEnv *env = sc.env;

        jobject sInstance = env->GetStaticObjectField(g_clsActivity, fid_sInstance);
        jobject imageReader = env->GetObjectField(sInstance, fid_imageReader);
        
        if(imageReader) {
            jobject image = env->CallObjectMethod(imageReader, mid_acquireLatestImage);
            if(image) {
                int format = env->CallIntMethod(image, mid_getFormat);
                if(format != IMAGE_FORMAT_YUV_420_888) {
                    env->CallVoidMethod(image, mid_close);
                    
                    env->DeleteLocalRef(image);
                    env->DeleteLocalRef(imageReader);
                    env->DeleteLocalRef(sInstance);
                    return false;
                }

                jobjectArray planes = reinterpret_cast<jobjectArray>(env->CallObjectMethod(image, mid_getPlanes));
                if(planes) {
                    int len = env->GetArrayLength(planes);
                    if (len == 3) {
                        jobject plan_0 = env->GetObjectArrayElement(planes, 0);
                        jobject plan_1 = env->GetObjectArrayElement(planes, 1);
                        jobject plan_2 = env->GetObjectArrayElement(planes, 2);

                        jobject mem_buff_0 = env->CallObjectMethod(plan_0, mid_getBuffer);
                        jobject mem_buff_1 = env->CallObjectMethod(plan_1, mid_getBuffer);
                        jobject mem_buff_2 = env->CallObjectMethod(plan_2, mid_getBuffer);

                        // int32_t yStride = env->CallIntMethod(plan_0, mid_getRowStride);
                        // int32_t uvStride = env->CallIntMethod(plan_1, mid_getRowStride);

                        uint8_t *yPixel = (uint8_t *)env->GetDirectBufferAddress(mem_buff_0);
                        uint8_t *vPixel = (uint8_t *)env->GetDirectBufferAddress(mem_buff_1);
                        uint8_t *uPixel = (uint8_t *)env->GetDirectBufferAddress(mem_buff_2);

                        int32_t yLen = env->GetDirectBufferCapacity(mem_buff_0);
                        int32_t vLen = env->GetDirectBufferCapacity(mem_buff_1);
                        int32_t uLen = env->GetDirectBufferCapacity(mem_buff_2);
                        int32_t uvPixelStride = env->CallIntMethod(plan_1, mid_getPixelStride);

                        if ( (uvPixelStride == 2) && (vPixel == uPixel + 1) && (yLen == frameWidth * frameHeight) && (uLen == ((yLen / 2) - 1)) && (vLen == uLen) ) {
                            colorFormat = COLOR_FormatYUV420SemiPlanar;
                        } else if ( (uvPixelStride == 1) && (vPixel == uPixel + uLen) && (yLen == frameWidth * frameHeight) && (uLen == yLen / 4) && (vLen == uLen) ) {
                            colorFormat = COLOR_FormatYUV420Planar;
                        } else {
                            colorFormat = COLOR_FormatUnknown;
                            env->CallVoidMethod(image, mid_close);

                            env->DeleteLocalRef(plan_0);
                            env->DeleteLocalRef(plan_1);
                            env->DeleteLocalRef(plan_2);

                            env->DeleteLocalRef(mem_buff_0);
                            env->DeleteLocalRef(mem_buff_1);
                            env->DeleteLocalRef(mem_buff_2);

                            env->DeleteLocalRef(planes);
                            env->DeleteLocalRef(image);
                            env->DeleteLocalRef(imageReader);
                            env->DeleteLocalRef(sInstance);
                            return false;
                        }

                        buffer.clear();
                        buffer.insert(buffer.end(), yPixel, yPixel + yLen);
                        buffer.insert(buffer.end(), uPixel, uPixel + yLen / 2);

                        env->DeleteLocalRef(plan_0);
                        env->DeleteLocalRef(plan_1);
                        env->DeleteLocalRef(plan_2);

                        env->DeleteLocalRef(mem_buff_0);
                        env->DeleteLocalRef(mem_buff_1);
                        env->DeleteLocalRef(mem_buff_2);
                    }
                    else {
                        env->CallVoidMethod(image, mid_close);

                        env->DeleteLocalRef(planes);
                        env->DeleteLocalRef(image);
                        env->DeleteLocalRef(imageReader);
                        env->DeleteLocalRef(sInstance);
                        return false;
                    }

                    // Free the local ref
                    env->DeleteLocalRef(planes);
                }

                env->CallVoidMethod(image, mid_close);

                env->DeleteLocalRef(image);
            }

            // Free the local ref
            env->DeleteLocalRef(imageReader);
        }
        // Free the local ref
        env->DeleteLocalRef(sInstance);
        return true;
    }

    bool isOpened() const CV_OVERRIDE { return true; }

    int getCaptureDomain() CV_OVERRIDE { return CAP_ANDROID_CAM; }

    bool retrieveFrame(int, OutputArray out) CV_OVERRIDE {
        if (buffer.empty()) {
            return false;
        }
        Mat yuv(frameHeight + frameHeight/2, frameWidth, CV_8UC1, buffer.data());
        if (colorFormat == COLOR_FormatYUV420Planar) {
            cv::cvtColor(yuv, out, cv::COLOR_YUV2BGR_YV12);
        }
        else if (colorFormat == COLOR_FormatYUV420SemiPlanar) {
            cv::cvtColor(yuv, out, cv::COLOR_YUV2BGR_NV21);
        }
        else {
            return false;
        }

        cv::transpose(out, out);
        if(index == 0)
            cv::flip(out, out, 1);
        else
            cv::flip(out, out, -1);
        return true;
    }

    double getProperty(int property_id) const CV_OVERRIDE {
        switch (property_id) {
            case CV_CAP_PROP_FRAME_WIDTH: return frameWidth;
            case CV_CAP_PROP_FRAME_HEIGHT: return frameHeight;
        }
        return 0;
    }

    bool setProperty(int  property_id, double value) CV_OVERRIDE {
        switch (property_id) {
            case CV_CAP_PROP_FRAME_WIDTH:
                frameWidth = (int32_t)value;
                break;

            case CV_CAP_PROP_FRAME_HEIGHT:
                frameHeight = (int32_t)value;
                break;
        }
        return true;
    }
};

/****************** Implementation of interface functions ********************/

Ptr<IVideoCapture> cv::createAndroidCapture_cam( int index ) {
    Ptr<AndroidCameraCapture> res = makePtr<AndroidCameraCapture>();
    if (res && res->initCapture(index))
        return res;
    return Ptr<IVideoCapture>();
}
