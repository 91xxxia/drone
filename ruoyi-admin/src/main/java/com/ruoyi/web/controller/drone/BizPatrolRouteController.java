package com.ruoyi.web.controller.drone;

import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.system.domain.BizPatrolRoute;
import com.ruoyi.system.service.IBizPatrolRouteService;
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
@RequestMapping("/drone/route")
public class BizPatrolRouteController extends BaseController
{
    @Autowired
    private IBizPatrolRouteService routeService;

    @PreAuthorize("@ss.hasPermi('drone:route:list')")
    @GetMapping("/list")
    public TableDataInfo list(BizPatrolRoute query)
    {
        startPage();
        List<BizPatrolRoute> list = routeService.selectBizPatrolRouteList(query);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('drone:route:query')")
    @GetMapping("/{routeId}")
    public AjaxResult getInfo(@PathVariable Long routeId)
    {
        return success(routeService.selectBizPatrolRouteById(routeId));
    }

    @Log(title = "巡防航线", businessType = BusinessType.INSERT)
    @PreAuthorize("@ss.hasPermi('drone:route:add')")
    @PostMapping
    public AjaxResult add(@RequestBody BizPatrolRoute route)
    {
        if (!routeService.checkRouteNameUnique(route))
        {
            return error("新增航线失败，航线名称已存在");
        }
        route.setCreateBy(getUsername());
        return toAjax(routeService.insertBizPatrolRoute(route));
    }

    @Log(title = "巡防航线", businessType = BusinessType.UPDATE)
    @PreAuthorize("@ss.hasPermi('drone:route:edit')")
    @PutMapping
    public AjaxResult edit(@RequestBody BizPatrolRoute route)
    {
        if (!routeService.checkRouteNameUnique(route))
        {
            return error("修改航线失败，航线名称已存在");
        }
        route.setUpdateBy(getUsername());
        return toAjax(routeService.updateBizPatrolRoute(route));
    }

    @Log(title = "巡防航线", businessType = BusinessType.DELETE)
    @PreAuthorize("@ss.hasPermi('drone:route:remove')")
    @DeleteMapping("/{routeIds}")
    public AjaxResult remove(@PathVariable Long[] routeIds)
    {
        return toAjax(routeService.deleteBizPatrolRouteByIds(routeIds));
    }
}
