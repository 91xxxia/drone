package com.ruoyi.system.service;

import com.ruoyi.system.domain.BizDroneDashboard;

public interface IBizDroneDashboardService
{
    /**
     * 获取仪表板统计数据
     *
     * @return 统计数据对象
     */
    BizDroneDashboard getDashboardStats();
}