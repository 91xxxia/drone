package com.ruoyi.system.service;

import com.ruoyi.system.domain.BizPatrolTask;

import java.util.List;

public interface IBizPatrolTaskService
{
    BizPatrolTask selectBizPatrolTaskById(Long taskId);

    List<BizPatrolTask> selectBizPatrolTaskList(BizPatrolTask query);

    int insertBizPatrolTask(BizPatrolTask task, String operator);

    int updateBizPatrolTask(BizPatrolTask task);

    int deleteBizPatrolTaskByIds(Long[] taskIds);

    int startTask(Long taskId, String operator);

    int finishTask(Long taskId, String operator);

    int cancelTask(Long taskId, String operator);
}
