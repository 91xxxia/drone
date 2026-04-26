package com.ruoyi.system.mapper;

import com.ruoyi.system.domain.BizPatrolRoute;
import com.ruoyi.system.domain.BizPatrolRoutePoint;

import java.util.List;

public interface BizPatrolRouteMapper
{
    BizPatrolRoute selectBizPatrolRouteById(Long routeId);

    List<BizPatrolRoute> selectBizPatrolRouteList(BizPatrolRoute query);

    BizPatrolRoute selectBizPatrolRouteByName(String routeName);

    List<BizPatrolRoutePoint> selectBizPatrolRoutePointsByRouteId(Long routeId);

    int insertBizPatrolRoute(BizPatrolRoute route);

    int updateBizPatrolRoute(BizPatrolRoute route);

    int deleteBizPatrolRouteById(Long routeId);

    int deleteBizPatrolRouteByIds(Long[] routeIds);

    int insertBizPatrolRoutePoint(BizPatrolRoutePoint point);

    int deleteBizPatrolRoutePointByRouteId(Long routeId);
}
