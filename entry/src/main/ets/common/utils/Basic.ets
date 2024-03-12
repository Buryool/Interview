import display from '@ohos.display'
import deviceInfo from '@ohos.deviceInfo'

const designWidth = 375
const devicePhysics = display.getDefaultDisplaySync().width

export const vp2vp = (originSize: number) => {
  // 不是PAD是手机等比例缩放
  // if ( deviceInfo.deviceType !== 'tablet' ) {
  //   return px2vp(devicePhysics) / designWidth * originSize
  // }
  return originSize
}

// 分钟小时转换函数
export const formatTime = (time: number = 0, hasUnit: boolean = true) => {
  if (time < 3600) {
    return String(Math.floor(time / 60)) + (hasUnit ? ' 分钟' : '')
  } else {
    return String(Math.round(time / 3600 * 10) / 10) + (hasUnit ? ' 小时' : '')
  }
}