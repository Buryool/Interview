import http from '@ohos.net.http'
import { Auth } from './Auth'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { Logger } from './Logger'

export const BASE_URL = 'https://api-harmony-teach.itheima.net/hm/'

const req = http.createHttp()

// 声明箭头函数
const request = <T = unknown>(
  url: string,
  method: http.RequestMethod = http.RequestMethod.GET,
  params: object = {}
) => {
  // URL拼接
  let fullUrl = BASE_URL + url
  const options: http.HttpRequestOptions = {
    header: {
      'Content-Type': 'application/json',
    },
    readTimeout: 30000,
    method,
  }


  // 如果是GET方法则需要进一步处理
  if (method === http.RequestMethod.GET) {
    const urlParams: string[] = Object.keys(params).map(key => `${key}=${params[key]}`)
    fullUrl += `?${urlParams.join('&')}`
  } else {
    // 非GET请求的传参
    options.extraData = params
  }

  // 携带 token
  const user = Auth.getUser()
  if (user.token) {
    options.header['Authorization'] = `Bearer ${user.token}`
  }


  // 请求日志：
  Logger.info(`REQUEST→${url}→${method}`, JSON.stringify(params))
  return req.request(fullUrl, options)
    // 请求成功
    .then(res => {
      if (res.result) {
        // 响应日志：
        Logger.info(`RESPONSE→${url}→${method}`, res.result.toString().substring(0, 250))
        // 1. 处理响应
        const response = JSON.parse(res.result as string) as {
          code: number
          message: string
          data: T
        }
        if (response.code === 10000) {
          return response
        }
        // 2. 处理 token 失效
        if (response.code === 401) {
          Auth.delUser()
          router.pushUrl({
            url: 'pages/Login'
          }, router.RouterMode.Single) // 如果页面栈中已经存在LoginPage将不再限制页面栈，而是把LoginPage放在最顶部
        }
      }
      // 没有响应数据认为失败，业务状态码错误也失败
      return Promise.reject(res.result)
    })
      // 请求失败
    .catch(err => {
      promptAction.showToast({ message: '网络错误' })
      // 错误日志：
      Logger.error(`RESPONSE→${url}→${method}`, JSON.stringify(err).substring(0, 250))
      return Promise.reject(err)
    })
    .finally(() => {
      // 销毁请求释放资源
      req.destroy()
    })

}

export class Request {
  static get<T>(url: string, params?: object) {
    return request<T>(url, http.RequestMethod.GET, params)
  }

  static post<T>(url: string, params?: object) {
    return request<T>(url, http.RequestMethod.POST, params)
  }

  static put<T>(url: string, params?: object) {
    return request<T>(url, http.RequestMethod.PUT, params)
  }

  static delete<T>(url: string, params?: object) {
    return request<T>(url, http.RequestMethod.DELETE, params)
  }
}