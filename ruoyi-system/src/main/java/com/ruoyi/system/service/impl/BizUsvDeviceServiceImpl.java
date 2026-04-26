package com.ruoyi.system.service.impl;

import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.exception.ServiceException;
import com.ruoyi.system.domain.BizUsvDevice;
import com.ruoyi.system.mapper.BizPatrolTaskMapper;
import com.ruoyi.system.mapper.BizUsvDeviceMapper;
import com.ruoyi.system.service.IBizUsvDeviceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BizUsvDeviceServiceImpl implements IBizUsvDeviceService
{
    @Autowired
    private BizUsvDeviceMapper deviceMapper;

    @Autowired
    private BizPatrolTaskMapper taskMapper;

    @Override
    public BizUsvDevice selectBizUsvDeviceById(Long deviceId)
    {
        return deviceMapper.selectBizUsvDeviceById(deviceId);
    }

    @Override
    public List<BizUsvDevice> selectBizUsvDeviceList(BizUsvDevice query)
    {
        return deviceMapper.selectBizUsvDeviceList(query);
    }

    @Override
    public boolean checkDeviceCodeUnique(BizUsvDevice device)
    {
        Long deviceId = StringUtils.isNull(device.getDeviceId()) ? -1L : device.getDeviceId();
        BizUsvDevice existed = deviceMapper.selectBizUsvDeviceByCode(device.getDeviceCode());
        return StringUtils.isNull(existed) || existed.getDeviceId().longValue() == deviceId.longValue();
    }

    @Override
    public int insertBizUsvDevice(BizUsvDevice device)
    {
        if (StringUtils.isEmpty(device.getStatus()))
        {
            device.setStatus("normal");
        }
        return deviceMapper.insertBizUsvDevice(device);
    }

    @Override
    public int updateBizUsvDevice(BizUsvDevice device)
    {
        return deviceMapper.updateBizUsvDevice(device);
    }

    @Override
    public int deleteBizUsvDeviceByIds(Long[] deviceIds)
    {
        for (Long deviceId : deviceIds)
        {
            if (taskMapper.countRunningOrPendingTaskByDeviceId(deviceId) > 0)
            {
                throw new ServiceException("设备已绑定未完成任务，不能删除");
            }
        }
        return deviceMapper.deleteBizUsvDeviceByIds(deviceIds);
    }
}
