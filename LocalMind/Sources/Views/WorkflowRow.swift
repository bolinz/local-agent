import SwiftUI

struct WorkflowRow: View {
    let workflow: Workflow
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workflow.name)
                    .font(.headline)
                Text(workflow.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(workflow.trigger.label)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { workflow.isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
