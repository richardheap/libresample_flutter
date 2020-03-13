cmake_minimum_required(VERSION 3.4.1)

add_library( native_libresample

             SHARED

             ../ios/Classes/filterkit.c ../ios/Classes/lrsexport.c ../ios/Classes/resample.c ../ios/Classes/resamplesubs.c )
