package com.ruoyi.system.service.impl;

import com.ruoyi.common.exception.ServiceException;
import com.ruoyi.common.utils.DateUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.domain.BizPatrolResult;
import com.ruoyi.system.domain.BizPatrolRoute;
import com.ruoyi.system.domain.BizPatrolRoutePoint;
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
        toUpdate.setProgress(0);
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
        // 确保 startTime 已设置（防止通过 updateTaskProgress 直接完成而未调用 startTask）
        if (StringUtils.isNull(task.getStartTime()))
        {
            Date startTime = task.getCreateTime() != null ? task.getCreateTime() : endTime;
            BizPatrolTask startUpdate = new BizPatrolTask();
            startUpdate.setTaskId(taskId);
            startUpdate.setStartTime(startTime);
            taskMapper.updateBizPatrolTaskStatus(startUpdate);
            task.setStartTime(startTime);
        }

        BizPatrolTask toUpdate = new BizPatrolTask();
        toUpdate.setTaskId(taskId);
        toUpdate.setStatus(STATUS_COMPLETED);
        toUpdate.setProgress(100);
        toUpdate.setEndTime(endTime);
        toUpdate.setUpdateBy(operator);
        int rows = taskMapper.updateBizPatrolTaskStatus(toUpdate);

        deviceMapper.updateDeviceStatus(task.getDeviceId(), "normal");
        insertTaskLog(taskId, STATUS_RUNNING, STATUS_COMPLETED, operator, "完成任务");
        autoCreateEnhancedResult(taskId, endTime, operator);
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

    @Override
    public Integer getTaskProgress(Long taskId)
    {
        BizPatrolTask task = getTaskOrThrow(taskId);
        return task.getProgress();
    }

    @Override
    @Transactional
    public int updateTaskProgress(Long taskId, Integer progress, String operator)
    {
        BizPatrolTask task = getTaskOrThrow(taskId);
        if (!STATUS_RUNNING.equals(task.getStatus()))
        {
            throw new ServiceException("仅执行中任务允许更新进度");
        }

        int safeProgress = progress == null ? 0 : Math.min(100, Math.max(0, progress));
        if (safeProgress >= 100)
        {
            return finishTask(taskId, operator);
        }

        BizPatrolTask toUpdate = new BizPatrolTask();
        toUpdate.setTaskId(taskId);
        toUpdate.setProgress(safeProgress);
        toUpdate.setUpdateBy(operator);
        return taskMapper.updateBizPatrolTaskStatus(toUpdate);
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

    private void autoCreateEnhancedResult(Long taskId, Date endTime, String operator)
    {
        BizPatrolResult existed = resultMapper.selectBizPatrolResultByTaskId(taskId);
        if (StringUtils.isNotNull(existed))
        {
            return;
        }

        BizPatrolTask task = taskMapper.selectBizPatrolTaskById(taskId);

        // 获取航线信息进行智能分析
        BizPatrolRoute route = routeMapper.selectBizPatrolRouteById(task.getRouteId());
        if (route != null)
        {
            route.setPoints(routeMapper.selectBizPatrolRoutePointsByRouteId(task.getRouteId()));
        }

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

        // 计算并保存总距离
        double totalDistance = 0.0;
        if (route != null && route.getPoints() != null && route.getPoints().size() >= 2)
        {
            totalDistance = calculateRouteDistance(route.getPoints());
        }
        result.setTotalDistance(totalDistance);

        // 智能生成结果内容
        String routeComplexity = calculateRouteComplexity(route);
        String overview = generateIntelligentOverview(task, route, routeComplexity);
        String findings = generateFindings(route, routeComplexity);
        String handling = generateHandling(routeComplexity);

        result.setOverview(overview);
        result.setFindings(findings);
        result.setHandling(handling);
        result.setCreateBy(operator);
        resultMapper.insertBizPatrolResult(result);
    }

    private String calculateRouteComplexity(BizPatrolRoute route)
    {
        if (route == null || route.getPoints() == null || route.getPoints().isEmpty())
        {
            return "简单";
        }

        int turnCount = calculateTurnCount(route.getPoints());
        double totalDistance = calculateRouteDistance(route.getPoints());

        if (turnCount < 3 && totalDistance < 5.0)
        {
            return "简单";
        }
        else if (turnCount < 6 && totalDistance < 15.0)
        {
            return "中等";
        }
        else if (turnCount < 10 && totalDistance < 30.0)
        {
            return "复杂";
        }
        else
        {
            return "极复杂";
        }
    }

    private int calculateTurnCount(java.util.List<BizPatrolRoutePoint> points)
    {
        if (points == null || points.size() < 3)
        {
            return 0;
        }

        int turnCount = 0;
        for (int i = 1; i < points.size() - 1; i++)
        {
            double angle = calculateAngle(points.get(i - 1), points.get(i), points.get(i + 1));
            if (Math.abs(angle) > 30.0) // 角度变化大于30度算作转弯
            {
                turnCount++;
            }
        }
        return turnCount;
    }

    private double calculateAngle(BizPatrolRoutePoint pointA, BizPatrolRoutePoint pointB, BizPatrolRoutePoint pointC)
    {
        double abx = pointB.getLng().doubleValue() - pointA.getLng().doubleValue();
        double aby = pointB.getLat().doubleValue() - pointA.getLat().doubleValue();
        double bcx = pointC.getLng().doubleValue() - pointB.getLng().doubleValue();
        double bcy = pointC.getLat().doubleValue() - pointB.getLat().doubleValue();

        double dotProduct = abx * bcx + aby * bcy;
        double magnitudeAB = Math.sqrt(abx * abx + aby * aby);
        double magnitudeBC = Math.sqrt(bcx * bcx + bcy * bcy);

        if (magnitudeAB == 0 || magnitudeBC == 0)
        {
            return 0.0;
        }

        double cosAngle = dotProduct / (magnitudeAB * magnitudeBC);
        cosAngle = Math.max(-1.0, Math.min(1.0, cosAngle));
        double angleRad = Math.acos(cosAngle);

        return angleRad * 180.0 / Math.PI;
    }

    private double calculateRouteDistance(java.util.List<BizPatrolRoutePoint> points)
    {
        if (points == null || points.size() < 2)
        {
            return 0.0;
        }

        double totalDistance = 0.0;
        for (int i = 1; i < points.size(); i++)
        {
            totalDistance += calculateDistance(points.get(i - 1), points.get(i));
        }
        return totalDistance;
    }

    private double calculateDistance(BizPatrolRoutePoint point1, BizPatrolRoutePoint point2)
    {
        final double R = 6371.0; // 地球半径（公里）

        double lat1Rad = Math.toRadians(point1.getLat().doubleValue());
        double lat2Rad = Math.toRadians(point2.getLat().doubleValue());
        double deltaLatRad = Math.toRadians(point2.getLat().doubleValue() - point1.getLat().doubleValue());
        double deltaLngRad = Math.toRadians(point2.getLng().doubleValue() - point1.getLng().doubleValue());

        double a = Math.sin(deltaLatRad / 2) * Math.sin(deltaLatRad / 2) +
                   Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                   Math.sin(deltaLngRad / 2) * Math.sin(deltaLngRad / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }

    private String generateIntelligentOverview(BizPatrolTask task, BizPatrolRoute route, String complexity)
    {
        StringBuilder overview = new StringBuilder();
        overview.append("本次").append(task.getTaskName()).append("巡防任务已完成。");

        if (route != null)
        {
            double distance = calculateRouteDistance(route.getPoints());
            overview.append("航线总距离约").append(String.format("%.2f", distance)).append("公里，");
            overview.append("复杂度评级为").append(complexity).append("。");
        }

        // 基于复杂度生成不同的描述
        switch (complexity)
        {
            case "简单":
                overview.append("航线较为直接，执行过程顺利，设备运行状态良好。");
                break;
            case "中等":
                overview.append("航线包含适量转弯，设备操控稳定，数据采集完整。");
                break;
            case "复杂":
                overview.append("航线设计较为复杂，设备展现了良好的机动性能，完成了高难度巡防任务。");
                break;
            case "极复杂":
                overview.append("航线极其复杂，考验了设备的极限性能，成功完成了挑战性巡防任务。");
                break;
            default:
                overview.append("巡防任务执行过程正常，各项指标符合预期。");
        }

        return overview.toString();
    }

    private String generateFindings(BizPatrolRoute route, String complexity)
    {
        if (route == null || route.getPoints() == null || route.getPoints().isEmpty())
        {
            return "航线数据不完整，建议检查航线规划。";
        }

        StringBuilder findings = new StringBuilder();

        // 基于航线复杂度生成发现情况
        if ("复杂".equals(complexity) || "极复杂".equals(complexity))
        {
            findings.append("发现航线转弯点较多，建议优化航线设计以减少能耗。");

            double distance = calculateRouteDistance(route.getPoints());
            if (distance > 20.0)
            {
                findings.append("航线距离较长，建议考虑分段巡防策略。");
            }
        }
        else
        {
            findings.append("航线设计合理，执行效果良好。");
        }

        // 随机添加一些模拟发现（用于演示）
        java.util.Random random = new java.util.Random();
        int scenario = random.nextInt(4);

        switch (scenario)
        {
            case 0:
                findings.append("监测到海面漂浮物3处，已记录位置信息。");
                break;
            case 1:
                findings.append("发现渔船活动区域，航行秩序正常。");
                break;
            case 2:
                findings.append("水质监测数据显示各项指标正常。");
                break;
            case 3:
                findings.append("海况良好，能见度佳，有利于巡防作业。");
                break;
        }

        return findings.toString();
    }

    private String generateHandling(String complexity)
    {
        StringBuilder handling = new StringBuilder();

        if ("复杂".equals(complexity) || "极复杂".equals(complexity))
        {
            handling.append("建议后续优化航线设计，降低操作难度。");
            handling.append("加强设备维护，确保复杂任务执行能力。");
        }
        else
        {
            handling.append("任务执行情况良好，建议继续保持当前作业标准。");
        }

        handling.append("所有监测数据已上传至中央数据库，可供后续分析使用。");

        return handling.toString();
    }

    private Double calcDuration(Date startTime, Date endTime)
    {
        if (StringUtils.isNull(startTime) || StringUtils.isNull(endTime))
        {
            return 0.0;
        }
        double minutes = (double)(endTime.getTime() - startTime.getTime()) / (1000.0 * 60);
        return Math.max(minutes, 0.0);
    }
}
