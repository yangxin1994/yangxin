# encoding: utf-8
# already tidied up

module AgentTasksHelper

    def agent_task_status_tag(status)
        case status.to_i
        when 1
            "打开中"
        when 2
            "关闭"
        when 4
            "代理关闭"
        end
    end

end
