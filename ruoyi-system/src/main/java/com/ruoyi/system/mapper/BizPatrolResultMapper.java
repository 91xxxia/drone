package com.ruoyi.system.mapper;

import com.ruoyi.system.domain.BizPatrolResult;

import java.util.List;

public interface BizPatrolResultMapper
{
    BizPatrolResult selectBizPatrolResultById(Long resultId);

    BizPatrolResult selectBizPatrolResultByTaskId(Long taskId);

    List<BizPatrolResult> selectBizPatrolResultList(BizPatrolResult query);

    int insertBizPatrolResult(BizPatrolResult result);

    int updateBizPatrolResult(BizPatrolResult result);

    int deleteBizPatrolResultByIds(Long[] resultIds);

    int deleteBizPatrolResultByTaskIds(Long[] taskIds);
}
