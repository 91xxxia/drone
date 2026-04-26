package com.ruoyi.system.domain;

import java.math.BigDecimal;

public class BizPatrolRoutePoint
{
    private Long pointId;

    private Long routeId;

    private Integer seq;

    private BigDecimal lng;

    private BigDecimal lat;

    public Long getPointId()
    {
        return pointId;
    }

    public void setPointId(Long pointId)
    {
        this.pointId = pointId;
    }

    public Long getRouteId()
    {
        return routeId;
    }

    public void setRouteId(Long routeId)
    {
        this.routeId = routeId;
    }

    public Integer getSeq()
    {
        return seq;
    }

    public void setSeq(Integer seq)
    {
        this.seq = seq;
    }

    public BigDecimal getLng()
    {
        return lng;
    }

    public void setLng(BigDecimal lng)
    {
        this.lng = lng;
    }

    public BigDecimal getLat()
    {
        return lat;
    }

    public void setLat(BigDecimal lat)
    {
        this.lat = lat;
    }
}
