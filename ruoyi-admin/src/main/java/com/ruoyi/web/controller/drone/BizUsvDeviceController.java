package com.ruoyi.web.controller.drone;

import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.system.domain.BizUsvDevice;
import com.ruoyi.system.service.IBizUsvDeviceService;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/drone/device")
public class BizUsvDeviceController extends BaseController
{
    @Autowired
    private IBizUsvDeviceService deviceService;

    @PreAuthorize("@ss.hasPermi('drone:device:list')")
    @GetMapping("/list")
    public TableDataInfo list(BizUsvDevice query)
    {
        startPage();
        List<BizUsvDevice> list = deviceService.selectBizUsvDeviceList(query);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('drone:device:query')")
    @GetMapping("/{deviceId}")
    public AjaxResult getInfo(@PathVariable Long deviceId)
    {
        return success(deviceService.selectBizUsvDeviceById(deviceId));
    }

    @Log(title = "无人船设备", businessType = BusinessType.EXPORT)
    @PreAuthorize("@ss.hasPermi('drone:device:export')")
    @PostMapping("/export")
    public void export(HttpServletResponse response, BizUsvDevice query)
    {
        List<BizUsvDevice> list = deviceService.selectBizUsvDeviceList(query);
        ExcelUtil<BizUsvDevice> util = new ExcelUtil<>(BizUsvDevice.class);
        util.exportExcel(response, list, "无人船设备数据");
    }

    @Log(title = "无人船设备", businessType = BusinessType.INSERT)
    @PreAuthorize("@ss.hasPermi('drone:device:add')")
    @PostMapping
    public AjaxResult add(@RequestBody BizUsvDevice device)
    {
        if (!deviceService.checkDeviceCodeUnique(device))
        {
            return error("新增设备失败，设备编号已存在");
        }
        device.setCreateBy(getUsername());
        return toAjax(deviceService.insertBizUsvDevice(device));
    }

    @Log(title = "无人船设备", businessType = BusinessType.UPDATE)
    @PreAuthorize("@ss.hasPermi('drone:device:edit')")
    @PutMapping
    public AjaxResult edit(@RequestBody BizUsvDevice device)
    {
        if (!deviceService.checkDeviceCodeUnique(device))
        {
            return error("修改设备失败，设备编号已存在");
        }
        device.setUpdateBy(getUsername());
        return toAjax(deviceService.updateBizUsvDevice(device));
    }

    @Log(title = "无人船设备", businessType = BusinessType.DELETE)
    @PreAuthorize("@ss.hasPermi('drone:device:remove')")
    @DeleteMapping("/{deviceIds}")
    public AjaxResult remove(@PathVariable Long[] deviceIds)
    {
        return toAjax(deviceService.deleteBizUsvDeviceByIds(deviceIds));
    }
}
