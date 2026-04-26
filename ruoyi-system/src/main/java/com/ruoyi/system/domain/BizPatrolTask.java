package com.ruoyi.system.domain;

import com.ruoyi.common.annotation.Excel;
import com.ruoyi.common.core.domain.BaseEntity;
import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import java.util.Date;

public class BizPatrolTask extends BaseEntity
{
    private static final long serialVersionUID = 1L;

    private Long taskId;

    @Excel(name = "任务编号")
    private String taskCode;

    @Excel(name = "任务名称")
    private String taskName;

    @Excel(name = "执行人")
    private String executor;

    @Excel(name = "计划开始时间", width = 30, dateFormat = "yyyy-MM-dd HH:mm:ss")
    private Date plannedStartTime;

    private String taskDesc;

    private Long deviceId;

    @Excel(name = "设备名称")
    private String deviceName;

    private Long routeId;

    @Excel(name = "航线名称")
    private String routeName;

    @Excel(name = "任务状态")
    private String status;

    @Excel(name = "进度")
    private Integer progress;

    private Date startTime;

    private Date endTime;

    public Long getTaskId()
    {
        return taskId;
    }

    public void setTaskId(Long taskId)
    {
        this.taskId = taskId;
    }

    public String getTaskCode()
    {
        return taskCode;
    }

    public void setTaskCode(String taskCode)
    {
        this.taskCode = taskCode;
    }

    public String getTaskName()
    {
        return taskName;
    }

    public void setTaskName(String taskName)
    {
        this.taskName = taskName;
    }

    public String getExecutor()
    {
        return executor;
    }

    public void setExecutor(String executor)
    {
        this.executor = executor;
    }

    public Date getPlannedStartTime()
    {
        return plannedStartTime;
    }

    public void setPlannedStartTime(Date plannedStartTime)
    {
        this.plannedStartTime = plannedStartTime;
    }

    public String getTaskDesc()
    {
        return taskDesc;
    }

    public void setTaskDesc(String taskDesc)
    {
        this.taskDesc = taskDesc;
    }

    public Long getDeviceId()
    {
        return deviceId;
    }

    public void setDeviceId(Long deviceId)
    {
        this.deviceId = deviceId;
    }

    public String getDeviceName()
    {
        return deviceName;
    }

    public void setDeviceName(String deviceName)
    {
        this.deviceName = deviceName;
    }

    public Long getRouteId()
    {
        return routeId;
    }

    public void setRouteId(Long routeId)
    {
        this.routeId = routeId;
    }

    public String getRouteName()
    {
        return routeName;
    }

    public void setRouteName(String routeName)
    {
        this.routeName = routeName;
    }

    public String getStatus()
    {
        return status;
    }

    public void setStatus(String status)
    {
        this.status = status;
    }

    public Integer getProgress()
    {
        return progress;
    }

    public void setProgress(Integer progress)
    {
        this.progress = progress;
    }

    public Date getStartTime()
    {
        return startTime;
    }

    public void setStartTime(Date startTime)
    {
        this.startTime = startTime;
    }

    public Date getEndTime()
    {
        return endTime;
    }

    public void setEndTime(Date endTime)
    {
        this.endTime = endTime;
    }

    @Override
    public String toString()
    {
        return new ToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE)
            .append("taskId", getTaskId())
            .append("taskCode", getTaskCode())
            .append("taskName", getTaskName())
            .append("executor", getExecutor())
            .append("plannedStartTime", getPlannedStartTime())
            .append("taskDesc", getTaskDesc())
            .append("deviceId", getDeviceId())
            .append("routeId", getRouteId())
            .append("status", getStatus())
            .append("progress", getProgress())
            .append("startTime", getStartTime())
            .append("endTime", getEndTime())
            .append("createBy", getCreateBy())
            .append("createTime", getCreateTime())
            .append("updateBy", getUpdateBy())
            .append("updateTime", getUpdateTime())
            .toString();
    }
}
