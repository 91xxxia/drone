package com.ruoyi.system.mapper;

import com.ruoyi.system.domain.BizPatrolTask;
import com.ruoyi.system.domain.BizPatrolTaskLog;

import java.util.List;

public interface BizPatrolTaskMapper
{
    BizPatrolTask selectBizPatrolTaskById(Long taskId);

    List<BizPatrolTask> selectBizPatrolTaskList(BizPatrolTask query);

    int insertBizPatrolTask(BizPatrolTask task);

    int updateBizPatrolTask(BizPatrolTask task);

    int updateBizPatrolTaskStatus(BizPatrolTask task);

    int deleteBizPatrolTaskByIds(Long[] taskIds);

    int insertBizPatrolTaskLog(BizPatrolTaskLog log);

    int countRunningOrPendingTaskByDeviceId(Long deviceId);

    int countRunningOrPendingTaskByRouteId(Long routeId);
}
