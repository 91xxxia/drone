package com.ruoyi.system.domain;

import com.ruoyi.common.annotation.Excel;
import com.ruoyi.common.core.domain.BaseEntity;
import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import java.util.Date;

public class BizPatrolResult extends BaseEntity
{
    private static final long serialVersionUID = 1L;

    private Long resultId;

    @Excel(name = "结果编号")
    private String resultCode;

    private Long taskId;

    @Excel(name = "任务名称")
    private String taskName;

    private Long deviceId;

    @Excel(name = "无人船设备")
    private String deviceName;

    private Long routeId;

    @Excel(name = "巡防航线")
    private String routeName;

    @Excel(name = "巡防时长(分钟)")
    private Integer durationMinutes;

    @Excel(name = "完成时间", width = 30, dateFormat = "yyyy-MM-dd HH:mm:ss")
    private Date completedTime;

    @Excel(name = "执行人")
    private String executor;

    @Excel(name = "巡防概述")
    private String overview;

    @Excel(name = "发现情况")
    private String findings;

    private String handling;

    private String remark;

    public Long getResultId()
    {
        return resultId;
    }

    public void setResultId(Long resultId)
    {
        this.resultId = resultId;
    }

    public String getResultCode()
    {
        return resultCode;
    }

    public void setResultCode(String resultCode)
    {
        this.resultCode = resultCode;
    }

    public Long getTaskId()
    {
        return taskId;
    }

    public void setTaskId(Long taskId)
    {
        this.taskId = taskId;
    }

    public String getTaskName()
    {
        return taskName;
    }

    public void setTaskName(String taskName)
    {
        this.taskName = taskName;
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

    public Integer getDurationMinutes()
    {
        return durationMinutes;
    }

    public void setDurationMinutes(Integer durationMinutes)
    {
        this.durationMinutes = durationMinutes;
    }

    public Date getCompletedTime()
    {
        return completedTime;
    }

    public void setCompletedTime(Date completedTime)
    {
        this.completedTime = completedTime;
    }

    public String getExecutor()
    {
        return executor;
    }

    public void setExecutor(String executor)
    {
        this.executor = executor;
    }

    public String getOverview()
    {
        return overview;
    }

    public void setOverview(String overview)
    {
        this.overview = overview;
    }

    public String getFindings()
    {
        return findings;
    }

    public void setFindings(String findings)
    {
        this.findings = findings;
    }

    public String getHandling()
    {
        return handling;
    }

    public void setHandling(String handling)
    {
        this.handling = handling;
    }

    @Override
    public String getRemark()
    {
        return remark;
    }

    @Override
    public void setRemark(String remark)
    {
        this.remark = remark;
    }

    @Override
    public String toString()
    {
        return new ToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE)
            .append("resultId", getResultId())
            .append("resultCode", getResultCode())
            .append("taskId", getTaskId())
            .append("taskName", getTaskName())
            .append("deviceId", getDeviceId())
            .append("deviceName", getDeviceName())
            .append("routeId", getRouteId())
            .append("routeName", getRouteName())
            .append("durationMinutes", getDurationMinutes())
            .append("completedTime", getCompletedTime())
            .append("executor", getExecutor())
            .append("overview", getOverview())
            .append("findings", getFindings())
            .append("handling", getHandling())
            .append("remark", getRemark())
            .toString();
    }
}
