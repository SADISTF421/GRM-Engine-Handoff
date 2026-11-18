// R1 diagnostic wallmarks: 24-byte FVF::LIT. No normal or packed level UV.
uniform float4x4 m_VP;
struct vin { float3 position : POSITION; float4 color : COLOR0; float2 uv : TEXCOORD0; };
struct vout { float4 hpos : POSITION; float4 color : COLOR0; float2 uv : TEXCOORD0; };
vout main(vin I)
{
    vout O;
    O.hpos = mul(m_VP, float4(I.position, 1.0));
    O.color = I.color;
    O.uv = I.uv;
    return O;
}
