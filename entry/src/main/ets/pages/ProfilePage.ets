import { Auth, USER_KEY } from '../common/utils/Auth'
import { vp2vp } from '../common/utils/Basic'
import { Request } from '../common/utils/Request'
import { UserModel } from '../models/UserModel'
import promptAction from '@ohos.promptAction'
import { IvLoadingDialog } from '../common/components/IvLoadingDialog'
import picker from '@ohos.file.picker'
import fs from '@ohos.file.fs'
import request from '@ohos.request'
import { BASE_URL } from '../common/utils/Request'
import { Logger } from '../common/utils/Logger'

@Entry
@Component
struct ProfilePage {
  @StorageProp(USER_KEY)
  @Watch('updateUser')
  userJson: string = '{}'
  @State
  user: UserModel = JSON.parse(this.userJson)
  dialog: CustomDialogController = new CustomDialogController({
    builder: IvLoadingDialog({ message: '更新中...' }),
    customStyle: true
  })

  updateNickName() {
    this.dialog.open()
    Request.post('userInfo/profile', {
      nickName: this.user.nickName
    }).then(res => {
      Auth.setUser(this.user)
      this.dialog.close()
      promptAction.showToast({ message: '更新昵称成功' })
    })
      .catch(() => {
        this.dialog.close()
      })

  }

  updateUser() {
    this.user = JSON.parse(this.userJson)
  }

  URI: string = null

  pickerAvatar() {
    // 设置配置信息
    const photoSelectOptions = new picker.PhotoSelectOptions()
    photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE
    photoSelectOptions.maxSelectNumber = 1

    const photoViewPicker = new picker.PhotoViewPicker()
    photoViewPicker.select(photoSelectOptions).then(result => {
      // 1. 得到文件路径
      this.URI = result.photoUris[0]
      promptAction.showToast({ message: this.URI })
      this.uploadAvatar()
    })
  }

  uploadAvatar() {
    this.dialog.open()

    const context = getContext(this)
    const fileType = 'jpg'
    const fileName = Date.now() + '.' + fileType
    // 缓存的目录+文件的名称
    const copyFilePath = context.cacheDir + '/' + fileName

    // 读取选中的图片
    const file = fs.openSync(this.URI, fs.OpenMode.READ_ONLY)
    // 将读取到的图片拷贝到应用本身的缓存目录
    fs.copyFileSync(file.fd, copyFilePath)

    // 设置上传配置
    const config: request.UploadConfig = {
      url: BASE_URL + 'userInfo/avatar',
      method: 'POST',
      header: {
        'Accept': '*/*',
        'Authorization': `Bearer ${this.user.token}`,
        'Content-Type': 'multipart/form-data'
      },
      files: [
        { name: 'file', uri: `internal://cache/` + fileName, type: fileType, filename: fileName }
      ],
      data: []
    }

    // 开始上传
    request.uploadFile(context, config, (err, data) => {
      if (err) return Logger.error('UPLOAD', err.message)
      // 监听上传的进度
      data.on('progress', (size) => {
        Logger.info(size.toString())
      })
      // 上传完成回调
      data.on('complete', () => {
        this.getUserInfo()
      })
    })
  }

  // 从服务器获取到图片并保存到本地持久化
  getUserInfo () {
    Request.get<{ avatar: string }>('userInfo').then(res => {
      // 这里的avatar记录的是图片的地址 https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/teach/avatar/unittest/20240302/26949945055514624.jpg
      // Logger.debug("avatar", res.data.avatar)
      this.user.avatar = res.data.avatar
      Auth.setUser(this.user)
      this.dialog.close()
    })
  }

  build() {
    Navigation() {
      List() {
        ListItem() {
          Row() {
            Text('头像')
            Image(this.user.avatar)
              .alt('/common/images/avatar.png')
              .width(vp2vp(40))
              .aspectRatio(1)
              .borderRadius(vp2vp(20))
              .border({ width: 0.5, color: '#e4e4e4' })
              .onClick(() => {
                this.pickerAvatar()
              })
          }
          .width('100%')
          .height(vp2vp(60))
          .justifyContent(FlexAlign.SpaceBetween)
        }

        ListItem() {
          Row() {
            Text('昵称')
            TextInput({ text: this.user.nickName })
              .textAlign(TextAlign.End)
              .layoutWeight(1)
              .padding(0)
              .height(vp2vp(60))
              .backgroundColor(Color.White)
              .borderRadius(0)
              .onChange((value) => this.user.nickName = value)
              .onSubmit(() => {
                this.updateNickName()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: vp2vp(30), right: vp2vp(30), top: vp2vp(15), bottom: vp2vp(15) })
      .divider({ strokeWidth: 0.5, color: '#f5f5f5' })
    }
    .title('完善个人信息')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}