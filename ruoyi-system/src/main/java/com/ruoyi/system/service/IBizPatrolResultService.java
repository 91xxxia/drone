package com.ruoyi.system.service;

import com.ruoyi.system.domain.BizPatrolResult;

import java.util.List;

public interface IBizPatrolResultService
{
    BizPatrolResult selectBizPatrolResultById(Long resultId);

    List<BizPatrolResult> selectBizPatrolResultList(BizPatrolResult query);

    BizPatrolResult selectBizPatrolResultDetailById(Long resultId);

    int updateBizPatrolResult(BizPatrolResult result);

    int deleteBizPatrolResultByIds(Long[] resultIds);
}
