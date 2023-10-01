#include <metal_stdlib>
using namespace metal;


struct Fragment{
    float4 position [[position]];
    float pointSize [[point_size]] = 1.0f;
    float4 color;
};

vertex Fragment vertex_function (unsigned int instanceID [[instance_id]],
                                 constant float *parameters [[buffer(0)]])
{
    
    const float width = parameters[0];
    const float height = parameters[1];
    const float xoffset = parameters[2];
    const float yoffset = parameters[3];
    const float spacing = parameters[4];
   
    int xdots = floor((width - xoffset)/spacing) + 1;
    
    float non_normalized_x = xoffset + (instanceID % xdots) * spacing;
    float non_normalized_y = yoffset + (instanceID / xdots) * spacing;
    
    float normalized_x = non_normalized_x / width * 2 - 1;
    float normalized_y = non_normalized_y / height * 2 - 1;
    
    Fragment f;
    f.position = float4(normalized_x, normalized_y, 0, 1);
    
    return f;
    
}

fragment float4 fragment_function(Fragment in [[stage_in]])
{
    return float4(0.8,0.8,0.8,1);
}

