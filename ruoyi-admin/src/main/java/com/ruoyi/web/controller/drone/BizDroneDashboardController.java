package com.ruoyi.web.controller.drone;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.system.service.IBizDroneDashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/drone/dashboard")
public class BizDroneDashboardController extends BaseController
{
    @Autowired
    private IBizDroneDashboardService dashboardService;

    @PreAuthorize("@ss.hasPermi('drone:dashboard:view')")
    @GetMapping("/stats")
    public AjaxResult stats()
    {
        return success(dashboardService.getDashboardStats().getStats());
    }
}
