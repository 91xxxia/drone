package com.ruoyi.system.service.impl;

import com.ruoyi.common.exception.ServiceException;
import com.ruoyi.common.utils.DateUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.domain.BizPatrolResult;
import com.ruoyi.system.domain.BizPatrolRoute;
import com.ruoyi.system.domain.BizPatrolTask;
import com.ruoyi.system.domain.BizPatrolTaskLog;
import com.ruoyi.system.domain.BizUsvDevice;
import com.ruoyi.system.mapper.BizPatrolResultMapper;
import com.ruoyi.system.mapper.BizPatrolRouteMapper;
import com.ruoyi.system.mapper.BizPatrolTaskMapper;
import com.ruoyi.system.mapper.BizUsvDeviceMapper;
import com.ruoyi.system.service.IBizPatrolTaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;

@Service
public class BizPatrolTaskServiceImpl implements IBizPatrolTaskService
{
    private static final String STATUS_PENDING = "pending";
    private static final String STATUS_RUNNING = "running";
    private static final String STATUS_COMPLETED = "completed";
    private static final String STATUS_CANCELED = "canceled";

    @Autowired
    private BizPatrolTaskMapper taskMapper;

    @Autowired
    private BizPatrolResultMapper resultMapper;

    @Autowired
    private BizUsvDeviceMapper deviceMapper;

    @Autowired
    private BizPatrolRouteMapper routeMapper;

    @Override
    public BizPatrolTask selectBizPatrolTaskById(Long taskId)
    {
        return taskMapper.selectBizPatrolTaskById(taskId);
    }

    @Override
    public List<BizPatrolTask> selectBizPatrolTaskList(BizPatrolTask query)
    {
        return taskMapper.selectBizPatrolTaskList(query);
    }

    @Override
    @Transactional
    public int insertBizPatrolTask(BizPatrolTask task, String operator)
    {
        validateTaskCreation(task);
        task.setTaskCode(StringUtils.isEmpty(task.getTaskCode()) ? "TASK" + System.currentTimeMillis() : task.getTaskCode());
        task.setStatus(STATUS_PENDING);
        task.setProgress(0);
        task.setCreateBy(operator);
        int rows = taskMapper.insertBizPatrolTask(task);

        BizPatrolTaskLog log = new BizPatrolTaskLog();
        log.setTaskId(task.getTaskId());
        log.setFromStatus(null);
        log.setToStatus(STATUS_PENDING);
        log.setOperateBy(operator);
        log.setOperateTime(DateUtils.getNowDate());
        log.setRemark("任务创建");
        taskMapper.insertBizPatrolTaskLog(log);
        return rows;
    }

    @Override
    public int updateBizPatrolTask(BizPatrolTask task)
    {
        BizPatrolTask dbTask = taskMapper.selectBizPatrolTaskById(task.getTaskId());
        if (StringUtils.isNull(dbTask))
        {
            throw new ServiceException("任务不存在");
        }
        if (!STATUS_PENDING.equals(dbTask.getStatus()))
        {
            throw new ServiceException("仅待执行任务允许编辑");
        }
        validateTaskCreation(task);
        return taskMapper.updateBizPatrolTask(task);
    }

    @Override
    @Transactional
    public int deleteBizPatrolTaskByIds(Long[] taskIds)
    {
        for (Long taskId : taskIds)
        {
            BizPatrolTask task = taskMapper.selectBizPatrolTaskById(taskId);
            if (StringUtils.isNull(task))
            {
                continue;
            }
            if (STATUS_PENDING.equals(task.getStatus()) || STATUS_RUNNING.equals(task.getStatus()))
            {
                throw new ServiceException("仅已完成或已取消任务允许删除");
            }
        }
        resultMapper.deleteBizPatrolResultByTaskIds(taskIds);
        return taskMapper.deleteBizPatrolTaskByIds(taskIds);
    }

    @Override
    @Transactional
    public int startTask(Long taskId, String operator)
    {
        BizPatrolTask task = getTaskOrThrow(taskId);
        if (!STATUS_PENDING.equals(task.getStatus()))
        {
            throw new ServiceException("仅待执行任务允许开始");
        }

        BizPatrolTask toUpdate = new BizPatrolTask();
        toUpdate.setTaskId(taskId);
        toUpdate.setStatus(STATUS_RUNNING);
        toUpdate.setProgress(10);
        toUpdate.setStartTime(DateUtils.getNowDate());
        toUpdate.setUpdateBy(operator);
        int rows = taskMapper.updateBizPatrolTaskStatus(toUpdate);

        deviceMapper.updateDeviceStatus(task.getDeviceId(), "in_task");
        insertTaskLog(taskId, STATUS_PENDING, STATUS_RUNNING, operator, "开始任务");
        return rows;
    }

    @Override
    @Transactional
    public int finishTask(Long taskId, String operator)
    {
        BizPatrolTask task = getTaskOrThrow(taskId);
        if (!STATUS_RUNNING.equals(task.getStatus()))
        {
            throw new ServiceException("仅执行中任务允许完成");
        }

        Date endTime = DateUtils.getNowDate();
        BizPatrolTask toUpdate = new BizPatrolTask();
        toUpdate.setTaskId(taskId);
        toUpdate.setStatus(STATUS_COMPLETED);
        toUpdate.setProgress(100);
        toUpdate.setEndTime(endTime);
        toUpdate.setUpdateBy(operator);
        int rows = taskMapper.updateBizPatrolTaskStatus(toUpdate);

        deviceMapper.updateDeviceStatus(task.getDeviceId(), "normal");
        insertTaskLog(taskId, STATUS_RUNNING, STATUS_COMPLETED, operator, "完成任务");
        autoCreateResult(taskId, endTime, operator);
        return rows;
    }

    @Override
    @Transactional
    public int cancelTask(Long taskId, String operator)
    {
        BizPatrolTask task = getTaskOrThrow(taskId);
        if (!(STATUS_PENDING.equals(task.getStatus()) || STATUS_RUNNING.equals(task.getStatus())))
        {
            throw new ServiceException("仅待执行或执行中任务允许取消");
        }

        BizPatrolTask toUpdate = new BizPatrolTask();
        toUpdate.setTaskId(taskId);
        toUpdate.setStatus(STATUS_CANCELED);
        toUpdate.setEndTime(DateUtils.getNowDate());
        toUpdate.setUpdateBy(operator);
        int rows = taskMapper.updateBizPatrolTaskStatus(toUpdate);

        deviceMapper.updateDeviceStatus(task.getDeviceId(), "normal");
        insertTaskLog(taskId, task.getStatus(), STATUS_CANCELED, operator, "取消任务");
        return rows;
    }

    private void validateTaskCreation(BizPatrolTask task)
    {
        if (StringUtils.isEmpty(task.getTaskName()))
        {
            throw new ServiceException("任务名称不能为空");
        }
        if (StringUtils.isNull(task.getPlannedStartTime()))
        {
            throw new ServiceException("任务开始时间不能为空");
        }
        if (task.getPlannedStartTime().before(new Date()))
        {
            throw new ServiceException("任务开始时间不能早于当前时间");
        }

        BizUsvDevice device = deviceMapper.selectBizUsvDeviceById(task.getDeviceId());
        if (StringUtils.isNull(device))
        {
            throw new ServiceException("绑定设备不存在");
        }
        if (!"normal".equals(device.getStatus()))
        {
            throw new ServiceException("设备状态非正常，无法创建任务");
        }

        BizPatrolRoute route = routeMapper.selectBizPatrolRouteById(task.getRouteId());
        if (StringUtils.isNull(route))
        {
            throw new ServiceException("绑定航线不存在");
        }

        if (taskMapper.countRunningOrPendingTaskByDeviceId(task.getDeviceId()) > 0)
        {
            throw new ServiceException("该设备已有未完成任务，无法重复绑定");
        }
        if (taskMapper.countRunningOrPendingTaskByRouteId(task.getRouteId()) > 0)
        {
            throw new ServiceException("该航线已有未完成任务，无法重复绑定");
        }
    }

    private BizPatrolTask getTaskOrThrow(Long taskId)
    {
        BizPatrolTask task = taskMapper.selectBizPatrolTaskById(taskId);
        if (StringUtils.isNull(task))
        {
            throw new ServiceException("任务不存在");
        }
        return task;
    }

    private void insertTaskLog(Long taskId, String fromStatus, String toStatus, String operator, String remark)
    {
        BizPatrolTaskLog log = new BizPatrolTaskLog();
        log.setTaskId(taskId);
        log.setFromStatus(fromStatus);
        log.setToStatus(toStatus);
        log.setOperateBy(operator);
        log.setOperateTime(DateUtils.getNowDate());
        log.setRemark(remark);
        taskMapper.insertBizPatrolTaskLog(log);
    }

    private void autoCreateResult(Long taskId, Date endTime, String operator)
    {
        BizPatrolResult existed = resultMapper.selectBizPatrolResultByTaskId(taskId);
        if (StringUtils.isNotNull(existed))
        {
            return;
        }

        BizPatrolTask task = taskMapper.selectBizPatrolTaskById(taskId);
        BizPatrolResult result = new BizPatrolResult();
        result.setResultCode("RES" + System.currentTimeMillis() + taskId);
        result.setTaskId(task.getTaskId());
        result.setTaskName(task.getTaskName());
        result.setDeviceId(task.getDeviceId());
        result.setDeviceName(task.getDeviceName());
        result.setRouteId(task.getRouteId());
        result.setRouteName(task.getRouteName());
        result.setDurationMinutes(calcDuration(task.getStartTime(), endTime));
        result.setCompletedTime(endTime);
        result.setExecutor(task.getExecutor());
        result.setOverview("本次巡防任务正常完成，无异常情况");
        result.setCreateBy(operator);
        resultMapper.insertBizPatrolResult(result);
    }

    private Integer calcDuration(Date startTime, Date endTime)
    {
        if (StringUtils.isNull(startTime) || StringUtils.isNull(endTime))
        {
            return 0;
        }
        long minutes = (endTime.getTime() - startTime.getTime()) / (1000 * 60);
        return (int) Math.max(minutes, 0);
    }
}
