//
//  lrsexport.c
//  libresample_flutter
//
//  Created by Richard Heap on 1/15/20.
//

#include "resample_defs.h"
#include "lrsexport.h"
#include "libresample.h"

void* lrs_open(WORD highQuality,
               double minFactor,
               double maxFactor) {
    return resample_open(highQuality, minFactor, maxFactor);
}

//void *resample_dup(const void *handle);

//int resample_get_filter_width(const void *handle);

WORD lrs_process(void *handle,
                double factor,
                float *inBuffer,
                WORD inBufferLen,
                WORD lastFlag,
                WORD *inBufferUsed,
                float *outBuffer,
                WORD outBufferLen) {
    return resample_process(handle, factor, inBuffer, inBufferLen, lastFlag, inBufferUsed, outBuffer, outBufferLen);
}

void lrs_close(void *handle) {
    resample_close(handle);
}

//__attribute__((visibility("default"))) __attribute__((used))
//void resample_close(void *handle) {}
