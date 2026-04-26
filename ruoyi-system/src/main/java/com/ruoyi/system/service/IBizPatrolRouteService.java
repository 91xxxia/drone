package com.ruoyi.system.service;

import com.ruoyi.system.domain.BizPatrolRoute;

import java.util.List;

public interface IBizPatrolRouteService
{
    BizPatrolRoute selectBizPatrolRouteById(Long routeId);

    List<BizPatrolRoute> selectBizPatrolRouteList(BizPatrolRoute query);

    boolean checkRouteNameUnique(BizPatrolRoute route);

    int insertBizPatrolRoute(BizPatrolRoute route);

    int updateBizPatrolRoute(BizPatrolRoute route);

    int deleteBizPatrolRouteByIds(Long[] routeIds);
}
