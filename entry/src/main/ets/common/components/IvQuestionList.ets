import promptAction from '@ohos.promptAction'
import { BasicDataSource } from '../../models/BasicDataSource'
import { QueryQuestionListParams, QuestionItemModel } from '../../models/QuestionItemModel'
import { vp2vp } from '../utils/Basic'
import { Request } from '../utils/Request'
import { IvQuestionItem } from './IvQuestionItem'

// LazyForEach的数据源
class QuestionListDataSource extends BasicDataSource {
  private questionList: QuestionItemModel[] = []

  totalCount() {
    return this.questionList.length
  }

  getData(index: number): QuestionItemModel {
    return this.questionList[index]
  }

  public addData(index: number, data: QuestionItemModel): void {
    this.questionList.splice(index, 0, data);
    this.notifyDataAdd(index);
  }

  public pushData(data: QuestionItemModel): void {
    this.questionList.push(data);
    this.notifyDataAdd(this.questionList.length - 1);
  }
}

@Component
export struct IvQuestionList {
  @Prop
  questionType: number
  @Prop
  @Watch('initQuestionList')
  activeIndex: number
  selfIndex: number
  params: QueryQuestionListParams = {
    questionBankType: 10,
    type: this.questionType,
    page: 1,
    sort: 0,
  }
  @State
  questionList: QuestionItemModel[] = []

  // 触底加载相关
  @State
  finished: boolean = false
  @State
  loading: boolean = false
  questionListDataSource = new QuestionListDataSource()

  aboutToAppear() {
    this.initQuestionList()
  }

  initQuestionList() {
    if (this.activeIndex === this.selfIndex && this.questionListDataSource.totalCount() === 0) {
      this.getQuestionList()
    }
  }

  getQuestionList() {
    if (this.loading || this.finished) return
    this.loading = true

    return Request.get<{
      total: number,
      pageTotal: number,
      rows: QuestionItemModel[]
    }>('question/list', this.params)
      .then(res => {
        res.data.rows.forEach(item => {
          this.questionListDataSource.pushData(item)
        })
        if (this.params.page < res.data.pageTotal) {
          this.params.page++
        } else {
          this.finished = true
        }
        this.loading = false
      })
      .catch(e => {
        promptAction.showToast({ message: JSON.stringify(e) })
        this.loading = false
      })
  }

  @Builder
  LoadingBuilder() {
    if (this.finished) {
      Row() {
        Text('没有更多了~')
          .fontColor($r('app.color.gray'))
          .fontSize(vp2vp(14))
      }
      .width('100%')
      .height(vp2vp(50))
      .justifyContent(FlexAlign.Center)
    } else {
      if (this.loading) {
        Row() {
          LoadingProgress()
            .width(vp2vp(24))
            .margin({ right: vp2vp(5) })
          Text('加载中...')
            .fontColor($r('app.color.gray'))
            .fontSize(vp2vp(14))
        }
        .width('100%')
        .height(vp2vp(50))
        .justifyContent(FlexAlign.Center)
      }
    }
  }

  build() {
    List() {
      LazyForEach(this.questionListDataSource, (item: QuestionItemModel) => {
        ListItem() {
          IvQuestionItem({ item })
        }
      },
        ({id, likeCount, readFlag, views}: QuestionItemModel) => {
          return JSON.stringify({ id, likeCount, readFlag, views })
        }
      )
      ListItem() {
        this.LoadingBuilder()
      }
    }
    .divider({
      strokeWidth: 0.5,
      color: $r('app.color.gray_bg')
    })
    .padding({ left: vp2vp(15), right: vp2vp(15) })
    .height('100%')
    .width('100%')
    .onReachEnd(() => {
      // 实现触底加载
      this.getQuestionList()
    })
  }
}