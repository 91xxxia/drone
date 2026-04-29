package com.ruoyi.system.service.impl;

import com.ruoyi.system.domain.BizDroneDashboard;
import com.ruoyi.system.mapper.BizDroneDashboardMapper;
import com.ruoyi.system.service.IBizDroneDashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class BizDroneDashboardServiceImpl implements IBizDroneDashboardService
{
    @Autowired
    private BizDroneDashboardMapper dashboardMapper;

    @Override
    public BizDroneDashboard getDashboardStats()
    {
        Map<String, Object> statsMap = dashboardMapper.selectDashboardStats();
        BizDroneDashboard dashboard = new BizDroneDashboard();
        dashboard.setStats(statsMap);
        return dashboard;
    }
}