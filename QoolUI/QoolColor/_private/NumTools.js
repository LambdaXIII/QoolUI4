.pragma library

// NOTE(迁移) v3 Qool.Color/_private/NumTools.js 逐字迁移，含刻意怪癖，勿"修复"：
//   - simplifyChannelNumber 的 /^0+/g 去前导零使 "0.500" → ".500"（v3 显示怪癖，
//     滑块数值显示依赖此行为；zero2 去尾零被 v3 注释禁用，一并保留）。
//   - limitNumber 对 NaN 透传（Math.min/max 语义与 v3 NumberLimiter::keepAtEdges
//     一致：Math.min(1, NaN) 与 Math.max(0, NaN) 均为 NaN），消费方自行处理空输入。
//   - mapNumber 在 v3 无消费方，保留以维持 v3 源码对照完整（API 面）。
//
// 消费方：ColorSlider / ChannelSlider（simplifyChannelNumber + limitNumber）、
// ColorCursor / HSVSurface / HSLBox（limitNumber）。

/*!
    \brief Qool.Color 模块私有数值工具库（v3 NumTools.js 逐字迁移）。

    三个函数均与 v3 逐字一致：
    \list
    \li \c limitNumber(v, left, right)：按 min/max 顺序无关地裁剪到区间（NaN 透传）。
    \li \c simplifyChannelNumber(x)：0/1 原样返回，其余 \c toFixed(3) 后去除
        前导零（"0.500" → ".500"）——v3 显示怪癖，滑块数值文本依赖，勿改。
    \li \c mapNumber(x, in1, in2, out1, out2)：线性重映射（v3 无消费方，API 面保留）。
    \endlist
*/

function limitNumber(v, left, right) {
    const min = Math.min(left, right)
    const max = Math.max(left, right)

    if (v < min)
        return min
    if (v > max)
        return max
    return v
}

const zero1 = /^0+/g
const zero2 = /0+$/g

function simplifyChannelNumber(x) {
    if (x === 0)
        return '0'
    if (x === 1)
        return '1'
    let xx = x.toFixed(3)
    let result = xx.toString()
    result = result.replace(zero1, "")
    //    result = result.replace(zero2, "")
    return result
}

function mapNumber(x, in1, in2, out1, out2) {
    const min1 = Math.min(in1, in2)
    const max1 = Math.max(in1, in2)
    const min2 = Math.min(out1, out2)
    const max2 = Math.max(out1, out2)
    let distance1 = max1 - min1
    let pos1 = x - min1
    let ratio = pos1 / distance1
    let distance2 = max2 - max1
    let pos2 = distance2 * ratio
    let result = pos2 + min2
    return result
}
