#shader tesscont
#version 410

layout(vertices = 4) out;

#define min4(a,b,c,d) min(min(min(a, b), c), d)
#define max4(a,b,c,d) max(max(max(a, b), c), d)

in vec4 vColor[];
in vec2 vTexCoord[];
in vec3 vNormal[];
in vec3 vWorldPos[];
in float visibility[];
uniform vec3 camWorldPos;

uniform float fogStart = 10;
uniform float fogEnd = 40;

out Tess
{
    vec4 color;
    vec2 vTexCoord;
} Out[];

void main(void)
{
    

    if (gl_InvocationID == 0)
    {
        //getting face bounds to clamp cam pos to face to get distance
        float smallestX = min4(vWorldPos[0].x, vWorldPos[1].x, vWorldPos[2].x, vWorldPos[3].x);
        float smallestY = min4(vWorldPos[0].y, vWorldPos[1].y, vWorldPos[2].y, vWorldPos[3].y);
        float smallestZ = min4(vWorldPos[0].z, vWorldPos[1].z, vWorldPos[2].z, vWorldPos[3].z);
        float biggestX = max4(vWorldPos[0].x, vWorldPos[1].x, vWorldPos[2].x, vWorldPos[3].x);
        float biggestY = max4(vWorldPos[0].y, vWorldPos[1].y, vWorldPos[2].y, vWorldPos[3].y);
        float biggestZ = max4(vWorldPos[0].z, vWorldPos[1].z, vWorldPos[2].z, vWorldPos[3].z);
        vec3 camPosClampedToFace = vec3(clamp(camWorldPos.x, smallestX, biggestX), clamp(camWorldPos.y, smallestY, biggestY), clamp(camWorldPos.z, smallestZ, biggestZ));
        float faceSize = distance(vWorldPos[1], vWorldPos[3]);//length of diagonal line of face
        float distToFace = distance(camWorldPos, camPosClampedToFace);
        float tessFactor = 1.0F - ceil(distToFace * 0.1) * 10 / fogEnd;

        tessFactor = pow(tessFactor, 2);

        float level = (faceSize / 1.41421356237) * tessFactor * 1.25;
        gl_TessLevelInner[0] = level;
        gl_TessLevelInner[1] = level;
        gl_TessLevelOuter[0] = level;
        gl_TessLevelOuter[1] = level;
        gl_TessLevelOuter[2] = level;
        gl_TessLevelOuter[3] = level;
    }

    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
    Out[gl_InvocationID].color = vColor[gl_InvocationID];
    Out[gl_InvocationID].vTexCoord = vTexCoord[gl_InvocationID];
}

#shader tesseval
#version 410
layout(quads) in;

in Tess
{
    vec4 color;
    vec2 vTexCoord;
} In[];


out vec4 vColor;
out vec2 vTexCoord;
out float visibility;

uniform float fogStart = 10;
uniform float fogEnd = 40;

uniform mat4 viewMatrix;
uniform mat4 modelMatrix;

float positionResolution = 8192;
float innacuracyOverDistanceFactor = 16;

void main(void)
{
    vec4 xPosTop = mix(gl_in[0].gl_Position, gl_in[1].gl_Position, gl_TessCoord.x);// interpolate in horizontal direction between vert. 0 and 1
    vec4 xPosBottom = mix(gl_in[3].gl_Position, gl_in[2].gl_Position, gl_TessCoord.x);// interpolate in horizontal direction between vert. 3 and 2
    gl_Position = mix(xPosTop, xPosBottom, gl_TessCoord.y);// interpolate in vert direction
    //triangles do this: gl_Position = (gl_TessCoord.x * gl_in[0].gl_Position) + (gl_TessCoord.y * gl_in[1].gl_Position) + (gl_TessCoord.z * gl_in[2].gl_Position);

    vec4 xColorTop = mix(In[0].color, In[1].color, gl_TessCoord.x);// interpolate in horizontal color between vert. 0 and 1
    vec4 xColorBottom = mix(In[3].color, In[2].color, gl_TessCoord.x);// interpolate in horizontal color between vert. 3 and 2
    vColor = mix(xColorTop, xColorBottom, gl_TessCoord.y);
    //triangles do this: vColor = (gl_TessCoord.x * In[0].color) + (gl_TessCoord.y * In[1].color) + (gl_TessCoord.z * In[2].color);

    vec2 xUVTop = mix(In[0].vTexCoord, In[1].vTexCoord, gl_TessCoord.x);// interpolate in horizontal coord between vert. 0 and 1
    vec2 xUVBottom = mix(In[3].vTexCoord, In[2].vTexCoord, gl_TessCoord.x);// interpolate in horizontal coord between vert. 3 and 2
    vTexCoord = mix(xUVTop, xUVBottom, gl_TessCoord.y);
    //triangles do this: vTexCoord = (gl_TessCoord.x * In[0].vTexCoord) + (gl_TessCoord.y * In[1].vTexCoord) + (gl_TessCoord.z * In[2].vTexCoord);

    float distanceFromCam = length(gl_Position.xyz);
    visibility = (distanceFromCam - fogStart) / (fogEnd - fogStart);
    visibility = clamp(visibility, 0.0, 1.0);
    visibility = 1.0 - visibility;
    visibility *= visibility;
    distanceFromCam = clamp(gl_Position.w, -1, 1000);
    //apply nostalgic vertex jitter
    gl_Position.xy = round(gl_Position.xy * (positionResolution / (distanceFromCam * innacuracyOverDistanceFactor))) / (positionResolution / (distanceFromCam * innacuracyOverDistanceFactor));

   
}