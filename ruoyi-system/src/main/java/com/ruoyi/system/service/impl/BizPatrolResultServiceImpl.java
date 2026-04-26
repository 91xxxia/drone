package com.ruoyi.system.service.impl;

import com.ruoyi.system.domain.BizPatrolResult;
import com.ruoyi.system.mapper.BizPatrolResultMapper;
import com.ruoyi.system.service.IBizPatrolResultService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BizPatrolResultServiceImpl implements IBizPatrolResultService
{
    @Autowired
    private BizPatrolResultMapper resultMapper;

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
