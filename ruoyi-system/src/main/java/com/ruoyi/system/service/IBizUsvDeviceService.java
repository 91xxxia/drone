package com.ruoyi.system.service;

import com.ruoyi.system.domain.BizUsvDevice;

import java.util.List;

public interface IBizUsvDeviceService
{
    BizUsvDevice selectBizUsvDeviceById(Long deviceId);

    List<BizUsvDevice> selectBizUsvDeviceList(BizUsvDevice query);

    boolean checkDeviceCodeUnique(BizUsvDevice device);

    int insertBizUsvDevice(BizUsvDevice device);

    int updateBizUsvDevice(BizUsvDevice device);

    int deleteBizUsvDeviceByIds(Long[] deviceIds);
}
