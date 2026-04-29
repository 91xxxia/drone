package com.ruoyi.system.domain;

import java.util.Map;

/**
 * 无人机仪表板数据对象
 *
 * @author ruoyi
 */
public class BizDroneDashboard
{
    private static final long serialVersionUID = 1L;

    /**
     * 统计数据
     */
    private Map<String, Object> stats;

    /**
     * 获取统计数据
     *
     * @return 统计数据Map
     */
    public Map<String, Object> getStats()
    {
        return stats;
    }

    /**
     * 设置统计数据
     *
     * @param stats 统计数据Map
     */
    public void setStats(Map<String, Object> stats)
    {
        this.stats = stats;
    }
}