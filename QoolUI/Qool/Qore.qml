pragma Singleton

import QtQuick
import Qool

QoolSingleton {
    function floatString(x, precision = 2, keep_zero = false) {
        // 处理精度为负数的情况
        if (precision < 0)
            precision = 0;

        // 计算四舍五入的值
        const factor = Math.pow(10, precision);
        const rounded = Math.round(x * factor) / factor;

        if (!keep_zero)
            return rounded;

        // 转换为字符串
        let str = rounded.toString();

        // 如果是整数，添加小数点
        if (!str.includes('.')) {
            str += '.';
        }

        // 分割整数和小数部分
        let splitted = str.split('.');
        let integer = splitted[0];
        let decimal = splitted[1];
        return `${integer}.${decimal.padEnd(precision, '0')}`;
    }
}
