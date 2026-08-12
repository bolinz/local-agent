import Foundation

struct WorkflowTemplate: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let summary: String
    let workflows: [Workflow]
}

enum TemplateStore {
    static let sampleTemplates: [WorkflowTemplate] = [
        WorkflowTemplate(
            name: "省钱管家",
            icon: "banknote.fill",
            summary: "还款提醒、账单整理等财务自动化",
            workflows: [
                Workflow(
                    name: "每月还款提醒",
                    summary: "每月1号提醒检查账单",
                    trigger: .time("0 9 1 * *"),
                    steps: [WorkflowStep(toolID: "reminder", arguments: ["title": "检查本月账单并还款"])]
                )
            ]
        ),
        WorkflowTemplate(
            name: "带娃神器",
            icon: "figure.and.child.holdinghands",
            summary: "睡前故事、作业提醒等育儿自动化",
            workflows: [
                Workflow(
                    name: "每日作业提醒",
                    summary: "每天下午5点提醒孩子写作业",
                    trigger: .time("0 17 * * *"),
                    steps: [WorkflowStep(toolID: "notification", arguments: ["title": "该写作业啦"])]
                )
            ]
        ),
        WorkflowTemplate(
            name: "长辈关怀",
            icon: "heart.text.square.fill",
            summary: "用药提醒、健康关怀等长辈自动化",
            workflows: [
                Workflow(
                    name: "每日用药提醒",
                    summary: "每天早中晚提醒服药",
                    trigger: .time("0 8 * * *"),
                    steps: [WorkflowStep(toolID: "notification", arguments: ["title": "该吃药了"])]
                )
            ]
        )
    ]
}
