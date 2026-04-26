package com.ruoyi.system.mapper;

import com.ruoyi.system.domain.BizUsvDevice;

import java.util.List;

public interface BizUsvDeviceMapper
{
    BizUsvDevice selectBizUsvDeviceById(Long deviceId);

    List<BizUsvDevice> selectBizUsvDeviceList(BizUsvDevice query);

    BizUsvDevice selectBizUsvDeviceByCode(String deviceCode);

    int insertBizUsvDevice(BizUsvDevice device);

    int updateBizUsvDevice(BizUsvDevice device);

    int updateDeviceStatus(Long deviceId, String status);

    int deleteBizUsvDeviceById(Long deviceId);

    int deleteBizUsvDeviceByIds(Long[] deviceIds);
}
