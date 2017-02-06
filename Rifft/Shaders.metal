//
//  Shaders.metal
//  Rifft
//
//  Created by Marius Petcu on 19/01/2017.
//  Copyright (c) 2017 Marius Petcu. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct VertexIn {
    packed_float3 position;
    packed_float2 texCoords;
};


struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
};

struct UniformData {
    float4x4 projection;
    float4x4 view;
    float4x4 model;
};

vertex VertexOut spriteVertex(uint vid [[ vertex_id ]],
                              device VertexIn *vertices  [[ buffer(0) ]],
                              constant UniformData *uniforms [[ buffer(1) ]])
{
    VertexOut outVertex;
    
    outVertex.position = uniforms->projection * uniforms->view * uniforms->model * float4(vertices[vid].position, 1.0);
    outVertex.texCoords = vertices[vid].texCoords;
    
    return outVertex;
};

fragment float4 spriteFragment(VertexOut inFrag [[stage_in]],
                               texture2d<float> texture [[ texture(0) ]])
{
    constexpr sampler sampler2D(coord::normalized,
                                address::repeat,
                                filter::linear);
    
    return texture.sample(sampler2D, inFrag.texCoords);
};
