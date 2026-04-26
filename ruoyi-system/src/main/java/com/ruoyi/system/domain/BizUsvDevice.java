package com.ruoyi.system.domain;

import com.ruoyi.common.annotation.Excel;
import com.ruoyi.common.core.domain.BaseEntity;
import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

public class BizUsvDevice extends BaseEntity
{
    private static final long serialVersionUID = 1L;

    private Long deviceId;

    @Excel(name = "设备编号")
    private String deviceCode;

    @Excel(name = "设备名称")
    private String deviceName;

    @Excel(name = "设备型号")
    private String deviceModel;

    @Excel(name = "续航时长(分钟)")
    private Integer enduranceMinutes;

    @Excel(name = "摄像头参数")
    private String cameraSpec;

    @Excel(name = "归属人")
    private String ownerName;

    @Excel(name = "设备状态")
    private String status;

    private String remark;

    public Long getDeviceId()
    {
        return deviceId;
    }

    public void setDeviceId(Long deviceId)
    {
        this.deviceId = deviceId;
    }

    public String getDeviceCode()
    {
        return deviceCode;
    }

    public void setDeviceCode(String deviceCode)
    {
        this.deviceCode = deviceCode;
    }

    public String getDeviceName()
    {
        return deviceName;
    }

    public void setDeviceName(String deviceName)
    {
        this.deviceName = deviceName;
    }

    public String getDeviceModel()
    {
        return deviceModel;
    }

    public void setDeviceModel(String deviceModel)
    {
        this.deviceModel = deviceModel;
    }

    public Integer getEnduranceMinutes()
    {
        return enduranceMinutes;
    }

    public void setEnduranceMinutes(Integer enduranceMinutes)
    {
        this.enduranceMinutes = enduranceMinutes;
    }

    public String getCameraSpec()
    {
        return cameraSpec;
    }

    public void setCameraSpec(String cameraSpec)
    {
        this.cameraSpec = cameraSpec;
    }

    public String getOwnerName()
    {
        return ownerName;
    }

    public void setOwnerName(String ownerName)
    {
        this.ownerName = ownerName;
    }

    public String getStatus()
    {
        return status;
    }

    public void setStatus(String status)
    {
        this.status = status;
    }

    @Override
    public String getRemark()
    {
        return remark;
    }

    @Override
    public void setRemark(String remark)
    {
        this.remark = remark;
    }

    @Override
    public String toString()
    {
        return new ToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE)
            .append("deviceId", getDeviceId())
            .append("deviceCode", getDeviceCode())
            .append("deviceName", getDeviceName())
            .append("deviceModel", getDeviceModel())
            .append("enduranceMinutes", getEnduranceMinutes())
            .append("cameraSpec", getCameraSpec())
            .append("ownerName", getOwnerName())
            .append("status", getStatus())
            .append("remark", getRemark())
            .append("createBy", getCreateBy())
            .append("createTime", getCreateTime())
            .append("updateBy", getUpdateBy())
            .append("updateTime", getUpdateTime())
            .toString();
    }
}
