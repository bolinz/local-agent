import Foundation

class DataFlowService {
    static let shared = DataFlowService()
    
    struct DataFlowInfo {
        let dataType: String
        let source: String
        let destination: String
        let isLocal: Bool
        let description: String
    }
    
    private init() {}
    
    func getChatDataFlow() -> [DataFlowInfo] {
        return [
            DataFlowInfo(
                dataType: "你的消息",
                source: "你的设备",
                destination: "本地模型",
                isLocal: true,
                description: "你的输入完全在你的设备上处理"
            ),
            DataFlowInfo(
                dataType: "AI回复",
                source: "本地模型",
                destination: "你的屏幕",
                isLocal: true,
                description: "AI生成的回复直接在设备上显示"
            )
        ]
    }
    
    func getWorkFlowDataFlow() -> [DataFlowInfo] {
        return [
            DataFlowInfo(
                dataType: "触发事件",
                source: "系统/时间",
                destination: "LocalMind",
                isLocal: true,
                description: "工作流触发器在本地监听"
            ),
            DataFlowInfo(
                dataType: "执行结果",
                source: "LocalMind",
                destination: "系统/通知",
                isLocal: true,
                description: "执行结果通过本地通知或系统接口完成"
            )
        ]
    }
    
    func getHealthDataFlow() -> [DataFlowInfo] {
        return [
            DataFlowInfo(
                dataType: "健康数据",
                source: "HealthKit",
                destination: "LocalMind",
                isLocal: true,
                description: "健康数据直接从 HealthKit 读取，不离设备"
            ),
            DataFlowInfo(
                dataType: "分析结果",
                source: "本地模型",
                destination: "你的屏幕",
                isLocal: true,
                description: "AI分析在本地完成，结果直接显示"
            )
        ]
    }
    
    func getCloudDataFlow() -> [DataFlowInfo]? {
        // 仅在用户配置了云端API时显示
        return nil
    }
}
