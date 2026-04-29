package com.ruoyi.system.mapper;

import java.util.Map;

/**
 * 无人机仪表板数据访问层
 *
 * @author ruoyi
 */
public interface BizDroneDashboardMapper
{
    /**
     * 查询仪表板统计数据
     *
     * @return 统计数据Map
     */
    Map<String, Object> selectDashboardStats();
}
