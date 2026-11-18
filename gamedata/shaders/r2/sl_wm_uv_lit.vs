// Diagnostic runtime wallmark input: FVF::LIT, 24 bytes.
// World position / D3DCOLOR / float UV. No packed-level UV decoding.
uniform float4x4 m_VP;
struct vin
{
    float3 position : POSITION;
    float4 color : COLOR0;
    float2 uv : TEXCOORD0;
};
struct vout
{
    float4 hpos : POSITION;
    float2 uv : TEXCOORD0;
    float4 color : COLOR0;
};
vout main(vin I)
{
    vout O;
    O.hpos = mul(m_VP, float4(I.position, 1.0));
    O.uv = I.uv;
    O.color = I.color;
    return O;
}
