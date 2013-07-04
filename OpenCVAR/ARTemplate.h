//
//  ARTemplate.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 20/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#ifndef __OpenCVAR__ARTemplate__
#define __OpenCVAR__ARTemplate__

#include <iostream>
#include "ARConstants.h"

class ARTemplate
{
public:
    ARTemplate(int templateId, cv::Mat &srcMat, cv::Size size = cv::Size(TEMPLATE_SIZE,TEMPLATE_SIZE), int binaryThreshold = BINARY_THRESHOLD );
    
    virtual ~ARTemplate();

    /** compare potential marker with this template - if successful then orientation value is return otherwise -1) */
    int match(cv::Mat &mat, float threshold);
    
    int getId(){
        return id;
    }
    
    cv::Mat& getTemplateMatAtIndex(int index){
        return templates[index];
    }
    
protected:
    
    //id of  the template
    int id;
    
    std::vector<cv::Mat> templates;        
};

#endif /* defined(__OpenCVAR__ARTemplate__) */
