package com.ruoyi.system.service.impl;

import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.domain.BizPatrolResult;
import com.ruoyi.system.domain.BizPatrolResultMedia;
import com.ruoyi.system.domain.BizPatrolRoutePoint;
import com.ruoyi.system.mapper.BizPatrolResultMapper;
import com.ruoyi.system.mapper.BizPatrolRouteMapper;
import com.ruoyi.system.service.IBizPatrolResultService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BizPatrolResultServiceImpl implements IBizPatrolResultService
{
    @Autowired
    private BizPatrolResultMapper resultMapper;

    @Autowired
    private BizPatrolRouteMapper routeMapper;

    @Override
    public BizPatrolResult selectBizPatrolResultById(Long resultId)
    {
        return resultMapper.selectBizPatrolResultById(resultId);
    }

    @Override
    public List<BizPatrolResult> selectBizPatrolResultList(BizPatrolResult query)
    {
        return resultMapper.selectBizPatrolResultList(query);
    }

    @Override
    public BizPatrolResult selectBizPatrolResultDetailById(Long resultId)
    {
        BizPatrolResult result = resultMapper.selectBizPatrolResultById(resultId);
        if (StringUtils.isNotNull(result))
        {
            result.setRoutePoints(routeMapper.selectBizPatrolRoutePointsByRouteId(result.getRouteId()));
            result.setMediaList(resultMapper.selectBizPatrolResultMediaByResultId(resultId));

            // 增强结果详情信息
            enhanceResultDetails(result);
        }
        return result;
    }

    private void enhanceResultDetails(BizPatrolResult result)
    {
        if (result.getRoutePoints() != null && !result.getRoutePoints().isEmpty())
        {
            // 如果数据库中没有存储总距离，则从航线点计算
            if (result.getTotalDistance() == null || result.getTotalDistance() == 0.0)
            {
                double totalDistance = calculateRouteDistance(result.getRoutePoints());
                result.setTotalDistance(totalDistance);
            }

            // 计算航线统计信息
            int turnCount = calculateTurnCount(result.getRoutePoints());
            String complexity = calculateComplexity(result.getRoutePoints());

            // 设置增强信息到备注字段（临时使用）
            String enhancedInfo = String.format("距离:%.2fkm;转弯:%d次;复杂度:%s;",
                result.getTotalDistance(), turnCount, complexity);

            if (StringUtils.isEmpty(result.getRemark()))
            {
                result.setRemark(enhancedInfo);
            }
            else
            {
                result.setRemark(enhancedInfo + result.getRemark());
            }
        }

        // 处理媒体列表，添加AI标签信息
        if (result.getMediaList() != null && !result.getMediaList().isEmpty())
        {
            enhanceMediaWithAITags(result.getMediaList());
        }
    }

    private double calculateRouteDistance(java.util.List<BizPatrolRoutePoint> points)
    {
        if (points == null || points.size() < 2)
        {
            return 0.0;
        }

        double totalDistance = 0.0;
        for (int i = 1; i < points.size(); i++)
        {
            totalDistance += calculateDistance(points.get(i - 1), points.get(i));
        }
        return totalDistance;
    }

    private double calculateDistance(BizPatrolRoutePoint point1, BizPatrolRoutePoint point2)
    {
        final double R = 6371.0; // 地球半径（公里）

        double lat1Rad = Math.toRadians(point1.getLat().doubleValue());
        double lat2Rad = Math.toRadians(point2.getLat().doubleValue());
        double deltaLatRad = Math.toRadians(point2.getLat().doubleValue() - point1.getLat().doubleValue());
        double deltaLngRad = Math.toRadians(point2.getLng().doubleValue() - point1.getLng().doubleValue());

        double a = Math.sin(deltaLatRad / 2) * Math.sin(deltaLatRad / 2) +
                   Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                   Math.sin(deltaLngRad / 2) * Math.sin(deltaLngRad / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }

    private int calculateTurnCount(java.util.List<BizPatrolRoutePoint> points)
    {
        if (points == null || points.size() < 3)
        {
            return 0;
        }

        int turnCount = 0;
        for (int i = 1; i < points.size() - 1; i++)
        {
            double angle = calculateAngle(points.get(i - 1), points.get(i), points.get(i + 1));
            if (Math.abs(angle) > 30.0)
            {
                turnCount++;
            }
        }
        return turnCount;
    }

    private double calculateAngle(BizPatrolRoutePoint pointA, BizPatrolRoutePoint pointB, BizPatrolRoutePoint pointC)
    {
        double abx = pointB.getLng().doubleValue() - pointA.getLng().doubleValue();
        double aby = pointB.getLat().doubleValue() - pointA.getLat().doubleValue();
        double bcx = pointC.getLng().doubleValue() - pointB.getLng().doubleValue();
        double bcy = pointC.getLat().doubleValue() - pointB.getLat().doubleValue();

        double dotProduct = abx * bcx + aby * bcy;
        double magnitudeAB = Math.sqrt(abx * abx + aby * aby);
        double magnitudeBC = Math.sqrt(bcx * bcx + bcy * bcy);

        if (magnitudeAB == 0 || magnitudeBC == 0)
        {
            return 0.0;
        }

        double cosAngle = dotProduct / (magnitudeAB * magnitudeBC);
        cosAngle = Math.max(-1.0, Math.min(1.0, cosAngle));
        double angleRad = Math.acos(cosAngle);

        return angleRad * 180.0 / Math.PI;
    }

    private String calculateComplexity(java.util.List<BizPatrolRoutePoint> points)
    {
        if (points == null || points.isEmpty())
        {
            return "简单";
        }

        int turnCount = calculateTurnCount(points);
        double totalDistance = calculateRouteDistance(points);

        if (turnCount < 3 && totalDistance < 5.0)
        {
            return "简单";
        }
        else if (turnCount < 6 && totalDistance < 15.0)
        {
            return "中等";
        }
        else if (turnCount < 10 && totalDistance < 30.0)
        {
            return "复杂";
        }
        else
        {
            return "极复杂";
        }
    }

    private void enhanceMediaWithAITags(java.util.List<BizPatrolResultMedia> mediaList)
    {
        if (mediaList == null || mediaList.isEmpty())
        {
            return;
        }

        // 模拟AI识别结果
        String[] aiTags = {"海面漂浮物", "渔船", "海鸟群", "水质采样点", "航标", "珊瑚礁", "废弃渔网", "海洋生物"};
        String[] confidenceLevels = {"高", "中", "低"};

        java.util.Random random = new java.util.Random();

        for (BizPatrolResultMedia media : mediaList)
        {
            if (StringUtils.isEmpty(media.getAiTag()))
            {
                // 为每个媒体文件生成AI标签
                String tag = aiTags[random.nextInt(aiTags.length)];
                String confidence = confidenceLevels[random.nextInt(confidenceLevels.length)];
                media.setAiTag(tag + "(" + confidence + "置信度)");

                // 生成模拟的边界框坐标
                if (StringUtils.isEmpty(media.getBboxJson()))
                {
                    double x = 20 + random.nextDouble() * 60; // 20-80%
                    double y = 20 + random.nextDouble() * 60; // 20-80%
                    double w = 10 + random.nextDouble() * 30; // 10-40%
                    double h = 10 + random.nextDouble() * 30; // 10-40%

                    String bboxJson = String.format("{\"x\":%.1f,\"y\":%.1f,\"w\":%.1f,\"h\":%.1f}", x, y, w, h);
                    media.setBboxJson(bboxJson);
                }
            }
        }
    }

    @Override
    public int updateBizPatrolResult(BizPatrolResult result)
    {
        return resultMapper.updateBizPatrolResult(result);
    }

    @Override
    public int deleteBizPatrolResultByIds(Long[] resultIds)
    {
        return resultMapper.deleteBizPatrolResultByIds(resultIds);
    }
}
