package com.ruoyi.system.service.impl;

import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.exception.ServiceException;
import com.ruoyi.system.domain.BizPatrolRoute;
import com.ruoyi.system.domain.BizPatrolRoutePoint;
import com.ruoyi.system.mapper.BizPatrolTaskMapper;
import com.ruoyi.system.mapper.BizPatrolRouteMapper;
import com.ruoyi.system.service.IBizPatrolRouteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;

@Service
public class BizPatrolRouteServiceImpl implements IBizPatrolRouteService
{
    @Autowired
    private BizPatrolRouteMapper routeMapper;

    @Autowired
    private BizPatrolTaskMapper taskMapper;

    @Override
    public BizPatrolRoute selectBizPatrolRouteById(Long routeId)
    {
        BizPatrolRoute route = routeMapper.selectBizPatrolRouteById(routeId);
        if (StringUtils.isNull(route))
        {
            return null;
        }
        route.setPoints(routeMapper.selectBizPatrolRoutePointsByRouteId(routeId));
        return route;
    }

    @Override
    public List<BizPatrolRoute> selectBizPatrolRouteList(BizPatrolRoute query)
    {
        return routeMapper.selectBizPatrolRouteList(query);
    }

    @Override
    public boolean checkRouteNameUnique(BizPatrolRoute route)
    {
        Long routeId = StringUtils.isNull(route.getRouteId()) ? -1L : route.getRouteId();
        BizPatrolRoute existed = routeMapper.selectBizPatrolRouteByName(route.getRouteName());
        return StringUtils.isNull(existed) || existed.getRouteId().longValue() == routeId.longValue();
    }

    @Override
    @Transactional
    public int insertBizPatrolRoute(BizPatrolRoute route)
    {
        int rows = routeMapper.insertBizPatrolRoute(route);
        insertRoutePoints(route.getRouteId(), route.getPoints());
        return rows;
    }

    @Override
    @Transactional
    public int updateBizPatrolRoute(BizPatrolRoute route)
    {
        int rows = routeMapper.updateBizPatrolRoute(route);
        routeMapper.deleteBizPatrolRoutePointByRouteId(route.getRouteId());
        insertRoutePoints(route.getRouteId(), route.getPoints());
        return rows;
    }

    @Override
    @Transactional
    public int deleteBizPatrolRouteByIds(Long[] routeIds)
    {
        for (Long routeId : routeIds)
        {
            if (taskMapper.countRunningOrPendingTaskByRouteId(routeId) > 0)
            {
                throw new ServiceException("航线已绑定未完成任务，不能删除");
            }
        }
        return routeMapper.deleteBizPatrolRouteByIds(routeIds);
    }

    private void insertRoutePoints(Long routeId, List<BizPatrolRoutePoint> points)
    {
        List<BizPatrolRoutePoint> pointList = StringUtils.isNull(points) ? Collections.emptyList() : points;
        for (BizPatrolRoutePoint point : pointList)
        {
            point.setRouteId(routeId);
            routeMapper.insertBizPatrolRoutePoint(point);
        }
    }
}
