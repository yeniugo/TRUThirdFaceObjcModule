/*
 CommonVars.h
 
 Created by Xuexing.Zheng on 8/18/15.
 Copyright © 2015 Authen. All rights reserved.
 */

#ifndef _CommonVars_h
#define _CommonVars_h


/**
 人脸框各边界值, 框中各点的坐标值相对于{0, 0, 480, 640}而言
 **/
typedef struct tagFaceFrame
{
    float	left;   //人脸框左边界坐标
    float   top;    //人脸框上边界坐标
    float	right;  //人脸框右边界坐标
    float	bottom; //人脸框下边界坐标
} FaceFrame;

#endif
