//
//  Grid.metal
//  Rifft
//
//  Created by Marius Petcu on 19/01/2017.
//  Copyright (c) 2017 Marius Petcu. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct GridVertexIn {
    packed_float3 position;
    packed_float3 direction;
};


struct GridVertexOut {
    float4 position [[position]];
};

struct GridUniformData {
    float4x4 mvp;
    float pixelWidth;
    float pixelHeight;
};

vertex GridVertexOut gridVertex(uint vid [[ vertex_id ]],
                              device GridVertexIn *vertices  [[ buffer(0) ]],
                              constant GridUniformData *uniforms [[ buffer(1) ]])
{
    GridVertexOut outVertex;
    float4x4 mvp = uniforms->mvp;
    
    float4 pos = float4(vertices[vid].position, 1.0);
    float4 target = pos + float4(vertices[vid].direction, 0.0);
    
    float4 ndcPos = mvp * pos;
    float4 ndcTarget = mvp * target;
    
    float2 direction = ndcTarget.xy / ndcTarget.w - ndcPos.xy / ndcPos.w;
    float2 fromPixels = float2(uniforms->pixelWidth, uniforms->pixelHeight);
    float2 delta = cross(float3(normalize(direction / fromPixels), 0.0),
                         float3(0.0, 0.0, 1.0)).xy * fromPixels;
    
    outVertex.position = ndcPos + float4(delta.x, delta.y, 0, 0) * ndcPos.w;
    return outVertex;
};

fragment float4 gridFragment(GridVertexOut inFrag [[stage_in]])
{
    return float4(1.0, 1.0, 1.0, 1.0) * (1 - inFrag.position.z * 1.1);
};
