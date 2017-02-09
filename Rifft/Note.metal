//
//  Note.metal
//  Rifft
//
//  Created by Marius Petcu on 19/01/2017.
//  Copyright (c) 2017 Marius Petcu. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct NoteVertexIn {
    packed_float3 position;
};

struct NoteVertexOut {
    float4 position [[position]];
};

struct NoteUniformData {
    float4x4 mvp;
    float4 color;
};

vertex NoteVertexOut noteVertex(uint vid [[ vertex_id ]],
                                device NoteVertexIn *vertices  [[ buffer(0) ]],
                                constant NoteUniformData *uniforms [[ buffer(1) ]])
{
    NoteVertexOut outVertex;
    float4x4 mvp = uniforms->mvp;
    float4 pos = float4(vertices[vid].position, 1.0);
    outVertex.position = mvp * pos;
    return outVertex;
};

fragment float4 noteFragment(NoteVertexOut inFrag [[stage_in]],
                             constant NoteUniformData *uniforms [[ buffer(0) ]])
{
    return uniforms->color * (1 - inFrag.position.z);
};
