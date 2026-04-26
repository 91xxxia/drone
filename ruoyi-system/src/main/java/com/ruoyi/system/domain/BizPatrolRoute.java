package com.ruoyi.system.domain;

import com.ruoyi.common.annotation.Excel;
import com.ruoyi.common.core.domain.BaseEntity;
import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import java.math.BigDecimal;
import java.util.List;

public class BizPatrolRoute extends BaseEntity
{
    private static final long serialVersionUID = 1L;

    private Long routeId;

    @Excel(name = "航线名称")
    private String routeName;

    @Excel(name = "预计时长(分钟)")
    private Integer estDurationMinutes;

    @Excel(name = "航行高度")
    private BigDecimal altitude;

    private String remark;

    private List<BizPatrolRoutePoint> points;

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

    public Integer getEstDurationMinutes()
    {
        return estDurationMinutes;
    }

    public void setEstDurationMinutes(Integer estDurationMinutes)
    {
        this.estDurationMinutes = estDurationMinutes;
    }

    public BigDecimal getAltitude()
    {
        return altitude;
    }

    public void setAltitude(BigDecimal altitude)
    {
        this.altitude = altitude;
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

    public List<BizPatrolRoutePoint> getPoints()
    {
        return points;
    }

    public void setPoints(List<BizPatrolRoutePoint> points)
    {
        this.points = points;
    }

    @Override
    public String toString()
    {
        return new ToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE)
            .append("routeId", getRouteId())
            .append("routeName", getRouteName())
            .append("estDurationMinutes", getEstDurationMinutes())
            .append("altitude", getAltitude())
            .append("remark", getRemark())
            .append("createBy", getCreateBy())
            .append("createTime", getCreateTime())
            .append("updateBy", getUpdateBy())
            .append("updateTime", getUpdateTime())
            .toString();
    }
}
