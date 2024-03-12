import mediaquery from '@ohos.mediaquery'
import { Auth } from '../common/utils/Auth'
import { vp2vp } from '../common/utils/Basic'
import { Home } from '../views/Index/Home'
import { Interview } from '../views/Index/Interview'
import { Mine } from '../views/Index/Mine'
import { Project } from '../views/Index/Project'

// 初始化用户信息，以便后续AppStorage使用
Auth.initLocalUser()

class ToolBarItem {
  defaultIcon: string | Resource
  activeIcon: string | Resource
  label: string
}

@Entry
@Component
struct Index {
  @State
  activeIndex: number = 0

  @State
  isLandscape: boolean = false

  // 注册屏幕状态监听器
  listenerScreen = mediaquery.matchMediaSync('(orientation: landscape) and (device-type: tablet)')

  aboutToAppear() {
    // 注册屏幕状态改变的回调函数
    this.listenerScreen.on('change', (mediaQueryResult) => {
      this.isLandscape = mediaQueryResult.matches
    })
  }

  toolBars: ToolBarItem[] = [
    { defaultIcon: $r('app.media.home'), activeIcon: $r('app.media.home_select'), label: '首页' },
    { defaultIcon: $r('app.media.project'), activeIcon: $r('app.media.project_select'), label: '项目' },
    { defaultIcon: $r('app.media.interview'), activeIcon: $r('app.media.interview_select'), label: '面经' },
    { defaultIcon: $r('app.media.mine'), activeIcon: $r('app.media.mine_select'), label: '我的' }
  ]

  @Builder
  TabBarBuilder(item: ToolBarItem, index: number) {
    Column({ space: vp2vp(4) }) {
      Image(this.activeIndex === index ? item.activeIcon : item.defaultIcon)
        .width(vp2vp(24))
      Text(item.label)
        .fontSize(vp2vp(12))
        .fontColor(this.activeIndex === index ? '#000' : '#aaa')
    }
  }

  build() {
    Tabs({
      index: this.activeIndex,
    }) {
      ForEach(this.toolBars, (item: ToolBarItem, index: number) => {
        TabContent() {
          if (index ===0) Home()
          else if (index === 1) Project()
          else if (index === 2) Interview()
          else Mine()
        }
        .tabBar(this.TabBarBuilder(item, index))
      })
    }
    .barPosition(this.isLandscape ? BarPosition.Start : BarPosition.End)
    .vertical(this.isLandscape)
    .barHeight(this.isLandscape ? vp2vp(400) : vp2vp(50))
    .onChange(index => this.activeIndex = index)
  }
}