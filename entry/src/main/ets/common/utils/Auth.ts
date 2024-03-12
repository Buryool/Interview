import router from '@ohos.router'
import { UserModel } from '../../models/UserModel'

export const USER_KEY = 'interview-user'
// 登录白名单（不需要登录的页面）
const PASS_LIST = ['pages/LoginPage']

export class Auth {
  static initLocalUser() {
    // 持久化函数
    PersistentStorage.PersistProp(USER_KEY, '{}') // 默认存储空对象
  }

  static setUser(user: UserModel) {
    AppStorage.Set(USER_KEY, JSON.stringify(user))
  }

  static getUser(): UserModel {
    const str = AppStorage.Get<string>(USER_KEY) || '{}'
    return JSON.parse(str)
  }

  static delUser() {
    AppStorage.Set(USER_KEY, '{}')
  }

  // 需要登录页面使用
  static pushUrl(options: router.RouterOptions) {
    const user = this.getUser()
    // 既不在白名单里也没有登录
    if (!PASS_LIST.includes(options.url) && !user.token) {
      router.pushUrl({
        url: 'pages/LoginPage',
        params: {
          ...options.params,
          return_url: options.url
        }
      })

      return false
    }
    // 目标页不需要登录或者用户已经登录，则直接条跳转
    return router.pushUrl(options)
  }
}